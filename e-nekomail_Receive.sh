#!/bin/bash
export DISPLAY='unix:0.0'
#*******************************************************************************
# e-nekomail_Receive.sh
#
#    概要        ： e-ネコセキュアデリバー　受信
#
#    履歴        ：2020/09/28 Create by S.Takeuchi
#
#*******************************************************************************

# 認証キーセット
OcpApimSubscriptionKey="---hoge---"
srcName="e-nekomail_Receive_api.sh"
# mailId初期値
mailId=""
requesturi="https://fcms.i-securedeliver.jp"

# ログ出力用現在時刻確認
logTime=`date +%Y%m%d_%H%M%S`

# ログ出力先確認
log="/home/dycsales/data/logs/delive_import_logs/e-nekomail_Receive_${logTime}.log"
echo "---log---" >> $log 2>&1
echo $log >> $log 2>&1

# 保存するZIPディレクトリ
receive_dir="/home/dycsales/data/download/csv/received/"

# 引数の日付項目を取得
date_y=$1
date_m=$2
date_d=$3
date_ymd="${date_y}-${date_m}-${date_d}"

# 初回稼働確認
echo "------------------------------------------------" >> $log 2>&1
echo "${srcName} is start at ${date_ymd} ." >> $log 2>&1

# 受信一覧取得API実行
echo "受信一覧取得API" >> $log 2>&1
echo "Access ReceiveListApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/inbox" >> $log 2>&1
res=`curl  -X POST "$requesturi/sdms/mails/inbox/" \
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
# リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
# curl --verbose \
# res=`curl --verbose \
#       -X POST "$requesturi/sdms/mails/inbox/" \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d @- << EOF | jq
# {
#     "inboxMailStatus": "NOT_READ",
# 	"sendDateFrom": "${date_ymd}T00:00:00.000Z",
# 	"sendDateTo": "${date_ymd}T23:59:59.000Z",
# 	"skip": 0,
# 	"take": 1
# }
# EOF
# `

echo ${res} >> $log 2>&1
echo "Access ReceiveListApi End" >> $log 2>&1

# メールID取得
mailId=`echo ${res} | jq '.iwsdWebMail[].iwsdreceiver[].id'`
echo ${mailId} >> $log 2>&1
for key in $(echo ${res} | jq '.iwsdWebMail[].iwsdreceiver[].id'); do

    mailId=${key}
    echo "$requesturi/sdms/mails/inbox/$mailId" >> $log 2>&1

    # 受信詳細情報取得API実行
    res2=`curl  -X GET "$requesturi/sdms/mails/inbox/$mailId" \
          -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey"`

    # リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
    # res2=`curl --verbose \
    #   -X GET "$requesturi/sdms/mails/inbox/$mailId" \
    #   -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey"`

    echo ${res2} >> $log 2>&1
    echo "===" >> $log 2>&1
    echo "Access ReceiveShow End" >> $log 2>&1

    #ファイル名を配列に作成 
    arrayFileName=()
    for fileName in $(echo ${res2} | jq -r '.iwsdfile[].fileName'); do
        arrayFileName+=(${fileName})
    done

    # 複数ファイル存在したときに
    i=0
    for fileId in $(echo $res2 | jq -r '.iwsdfile[].id');
    do
        echo "---i---" >> $log 2>&1
        echo $fileId >> $log 2>&1
        echo "---array---" >> $log 2>&1
        echo $arrayFileName[$i] >> $log 2>&1


        # ダウンロード API実行
        echo "Access download Start" >> $log 2>&1
        echo "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" >> $log 2>&1
        
        # リクエストとレスポンスを表示するオプション付きのcurlコマンド
        # res3=`curl  --verbose \
        #             -X GET  "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" \
        #             -H "Ocp-Apim-Subscription-Key: ${OcpApimSubscriptionKey}" \
        #             -H "Content-Type: application/json" \
        #             -o "${receive_dir}${arrayFileName[${i}]}"`
        res3=`curl  -X GET  "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" \
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
return 0

