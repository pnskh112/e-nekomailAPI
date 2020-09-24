#!/bin/bash
export DISPLAY='unix:0.0'

# 認証キーセット
OcpApimSubscriptionKey="===hoge==="
srcName="e-nekomail_Receive_api.sh"
mailId=""
mailStatusMonitorTimer=""
requesturi="https://fcms.i-securedeliver.jp"

log="/home/vagrant/watir_src/Ruby/logs/delive_export_logs/e-nekomail_Receive_api.log"

echo "------------------------------------------------" >> $log 2>&1
echo "${srcName} is start." >> $log 2>&1

# 保存するZIPディレクトリ
# receive_dir="/home/dycsales/data/download/csv/received/"
receive_dir="./temp/"

# 引数の日付項目を取得
date_y=$1
date_m=$2
date_d=$3
date_ymd="${date_y}-${date_m}-${date_d}"
echo $date_ymd >> $log 2>&1

# 受信一覧取得API実行
echo "受信一覧取得API"
echo $json
echo "Access ReceiveListApi Start"
echo "$requesturi/sdms/mails/inbox"
# リクエストとレスポンスを表示するオプション付きのcurlコマンド
# curl --verbose \
#       -X POST \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d "$json" "$requesturi/sdms/mails/inbox/" >/dev/null
#	"inboxMailStatus": "READ",
res=`curl  -X POST "$requesturi/sdms/mails/inbox/" \
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      -d @- << EOF | jq
{
    "inboxMailStatus": "READ",
	"sendDateFrom": "${date_ymd}T00:00:00.000Z",
	"sendDateTo": "${date_ymd}T23:59:59.000Z",
	"skip": 0,
	"take": 1
}
EOF
`
echo ${res}
echo "Access ReceiveListApi End"

# メールID取得
mailId=`echo ${res} | jq '.iwsdWebMail[].iwsdreceiver[].id'`
echo ${mailId}
for key in $(echo ${res} | jq '.iwsdWebMail[].iwsdreceiver[].id'); do

    mailId=${key}
    echo "$requesturi/sdms/mails/inbox/$mailId" 

    # 受信詳細情報取得API実行
    # リクエストとレスポンスを表示するオプション付きのcurlコマンド
    # curl --verbose \
    #       -X GET \
    #       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
    #       -H "Content-Type: application/json" \
    #       -d "$json" "$requesturi/sdms/mails/$mailId/resume/$fileId" >/dev/null
    res2=`curl  -X GET "$requesturi/sdms/mails/inbox/$mailId" \
          -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey"
         `
    echo $res2
    echo "==="
    echo "Access ReceiveShow End"

    #ファイル名を配列に作成 
    arrayFileName=()
    for fileName in $(echo ${res2} | jq '.iwsdfile[].fileName'); do
        arrayFileName+=(${fileName})
    done

    i=0
    for fileId in $(echo $res2 | jq -r '.iwsdfile[].id');
    do
        echo "---i---"
        echo $fileId
        echo "---array---"
        echo $arrayFileName[$i]


        # ダウンロード API実行
        echo "Access download Start"
        echo "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/"
        
        # echo "$responseJson | jq -r '.iwsdfile[].id'" >> $log 2>&1
        # リクエストとレスポンスを表示するオプション付きのcurlコマンド
        # curl --verbose \
        #       -X GET \
        #       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
        #       -H "Content-Type: application/json" \
        #       -d "$json" "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}" >/dev/null
        # curl  -X GET \
        #       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
        #       -H "Content-Type: application/json" \
        #       -d "$json" \
        #       -O "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" >> $log 2>&1
        curl  -X GET  "$requesturi/sdms/mails/inbox/${mailId}/attachment/${fileId}/" \
              -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
              -H "Content-Type: application/json" \
              -o ${receive_dir}${arrayFileName[$i]}

        # iをインクリメント
        i=$((i + 1))        
        echo "Access download End"
    done
done
echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
exit 0
