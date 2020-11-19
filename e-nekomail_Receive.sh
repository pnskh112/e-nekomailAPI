#!/bin/bash
export DISPLAY='unix:0.0'
#*******************************************************************************
# e-nekomail_Receive.sh
#
#    概要        ： e-ネコセキュアデリバー　受信
#
#    履歴        ：2020/09/28 Create by hoge
#
#*******************************************************************************

# エラーハンドリングのために必要。
# -e: エラーが発生したら（exit statusが0以外だったら）スクリプトの実行を終了する
# -o pipefail: パイプラインの途中でエラーが発生してもスクリプトの実行を終了する
set -e -o pipefail

# 認証キーセット
OcpApimSubscriptionKey="---hoge---"
srcName="e-nekomail_Receive_api.sh"
# mailId初期値
mailId=""
requesturi="https://fcms.i-securedeliver.jp"

# ログ出力用現在時刻確認
logTime=`date +%Y%m%d_%H%M%S`

# ログ出力先確認
# log="/home/dycsales/data/logs/delive_import_logs/e-nekomail_Receive_${logTime}.log"
log="/home/vagrant/watir_src/Ruby/logs/delive_export_logs/e-nekomail_Receive_${logTime}.log"
echo "---log---" >> $log 2>&1
echo $log >> $log 2>&1

# 保存するZIPディレクトリ
# receive_dir="/home/dycsales/data/download/csv/received/"
receive_dir="./"


# 引数の日付項目を取得
date_y=$1
date_m=$2
date_d=$3
date_ymd="${date_y}-${date_m}-${date_d}"

# メイン処理
echo "------------------------------------------------" >> $log 2>&1
echo "${srcName} is start at ${date_ymd} ." >> $log 2>&1

# 受信一覧取得API実行
echo "受信一覧取得API実行" >> $log 2>&1
echo "Access ReceiveListApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/inbox" >> $log 2>&1
resGetMail=`curl  -X POST "$requesturi/sdms/mails/inbox/" \
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      -d @- << EOF | jq
{
    "inboxMailStatus": "NOT_READ",
	"sendDateFrom": "${date_ymd}T00:00:00.000Z",
	"sendDateTo": "${date_ymd}T23:59:59.000Z",
	"skip": 0,
	"take": 1
}
EOF
`

echo ${resGetMail} >> $log 2>&1
echo "Access ReceiveListApi End" >> $log 2>&1

# メールID取得
echo "メールID取得" >> $log 2>&1
mailId=`echo ${resGetMail} | jq '.iwsdWebMail[].iwsdreceiver[].id'`
echo "メールID：${mailId}" >> $log 2>&1
for key in $(echo ${resGetMail} | jq '.iwsdWebMail[].iwsdreceiver[].id'); do

    mailId=${key}
    echo "$requesturi/sdms/mails/inbox/$mailId" >> $log 2>&1

    # 受信詳細情報取得API実行
    echo "受信詳細情報取得API実行" >> $log 2>&1
    resGetDetail=`curl  -X GET "$requesturi/sdms/mails/inbox/$mailId" \
          -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey"`

    # リクエスト回数エラーがセキュアデリバー側の問題で起きることがあるためエラーキャッチを追加。
    if [[  $( echo $resGetDetail | jq 'select(contains({ statusCode: 429 }))') ]]; then
        echo "429Error Is Occured!!!!" >> $log 2>&1
        echo "---------------------------------------------------------------" >> $log 2>&1
        echo "セキュアデリバーから、リクエスト回数エラーが返されています。" >> $log 2>&1
        echo "時間をおいて再度日付を入力し、「紐付けデータ受信」押してください。" >> $log 2>&1
        echo "---------------------------------------------------------------" >> $log 2>&1
        exit 1
    fi

    echo ${resGetDetail} >> $log 2>&1
    echo "===" >> $log 2>&1
    echo "Access ReceiveShow End" >> $log 2>&1

    #ファイル名を配列に作成 
    arrayFileName=()
    for fileName in $(echo ${resGetDetail} | jq -r '.iwsdfile[].fileName'); do
        arrayFileName+=(${fileName})
    done

    # 複数ファイル存在したときにループ
    i=0
    for fileId in $(echo $resGetDetail | jq -r '.iwsdfile[].id');
    do
        echo "---fileId---" >> $log 2>&1
        echo $fileId >> $log 2>&1
        echo "---FileName---" >> $log 2>&1
        echo $arrayFileName[$i] >> $log 2>&1

        # ダウンロード API実行
        echo "ダウンロード API実行" >> $log 2>&1
        echo "Access download Start" >> $log 2>&1
        echo "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" >> $log 2>&1

        resShowResponse=`curl  -X GET  "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" \
                    -H "Ocp-Apim-Subscription-Key: ${OcpApimSubscriptionKey}" \
                    -H "Content-Type: application/json" \
                    -o "${receive_dir}${arrayFileName[${i}]}"`

        # iをインクリメント
        i=$((i + 1))        
        echo "Access download End" >> $log 2>&1
    done
done
echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
exit 0


