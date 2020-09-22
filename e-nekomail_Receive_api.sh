#!/bin/bash
export DISPLAY='unix:0.0'
# 認証キーセット
OcpApimSubscriptionKey="xxxhogehogexxx"
srcName="e-nekomail_Receive_api.sh"
mailId=""
mailStatusMonitorTimer=""
requesturi="https://fcms.i-securedeliver.jp"
log="/home/vagrant/watir_src/Ruby/logs/delive_export_logs/e-nekomail_Receive_api.log"
echo "------------------------------------------------" >> $log 2>&1
echo "${srcName} is start." >> $log 2>&1
# 保存するZIPディレクトリ
# receive_dir="../../../../../home/dycsales/data/download/csv/received/"
receive_dir="./temp/"
# 引数の日付項目を取得
date_y=$1
date_m=$2
date_d=$3
date_ymd="${date_y}-${date_m}-${date_d}"
echo $date_ymd >> $log 2>&1
# リクエストボディの定義
json=$(cat << EOS
{
  "inboxMailStatus": "NOT_READ",
  "sendDateFrom": "${date_ymd}T00:00:00.000Z",
  "sendDateTo" : "${date_ymd}T23:59:59.999Z"
}
EOS
)
# 受信一覧取得APIを実行。メールIDを取得
echo "受信一覧取得API" >> $log 2>&1
echo $json >> $log 2>&1
echo $json | jq '.inboxMailStatus' >> $log 2>&1
echo "Access ReceiveListApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/inbox" >> $log 2>&1
# リクエストとレスポンスを表示するオプション付きのcurlコマンド
# curl --verbose \
#       -X POST \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d "$json" "$requesturi/sdms/mails/inbox/" >/dev/null
curl  -X POST "$requesturi/sdms/mails/inbox/" \
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      -d "$json" >> $log 2>&1
echo "Access ReceiveListApi End" >> $log 2>&1
# メールID取得（仮）
# mailId="{:id}"
mailId="1"
# 受信詳細情報取得API実行
echo "Access ReceiveShow Start" >> $log 2>&1
echo "$requesturi/sdms/mails/$mailId/resume/$fileId" >> $log 2>&1
# リクエストボディの定義
json=$(cat << EOS
{
  "receiverId": ${mailId}
}
EOS
)
# リクエストとレスポンスを表示するオプション付きのcurlコマンド
# curl --verbose \
#       -X GET \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d "$json" "$requesturi/sdms/mails/$mailId/resume/$fileId" >/dev/null
curl  -X GET "$requesturi/sdms/mails/inbox/${mailId}" \
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      -d "$json" >> $log 2>&1
responseJson=$(cat << EOS
{
    "replyDeadline": null,
    "comment": "複数ファイル送信",
    "iwsdfile": [
        {
            "downloadCount": 0,
            "id": 14612016,
            "fileName": "AAAA.pdf",
            "fileSize": 145255
        },
        {
            "downloadCount": 0,
            "id": 14612019,
            "fileName": "test.txt",
            "fileSize": 2599
        },
        {
            "downloadCount": 0,
            "id": 14612018,
            "fileName": "test.csv",
            "fileSize": 47
        },
        {
            "downloadCount": 0,
            "id": 14612017,
            "fileName": "BBBBB.xls",
            "fileSize": 128000
        },
        {
            "downloadCount": 0,
            "id": 14612015,
            "fileName": "001.docx",
            "fileSize": 14509
        }
    ],
    "senderMailAddress": "AAAAA@AAAAA.com",
    "filesCount": 5,
    "iwsdreceiver": [
        {
            "id": 21310728,
            "status": "NOT_READ",
            "addressType": "To",
            "mailAddress1": "BBBBB@BBBBB.jp"
        }
    ],
    "repositoryType": 2,
    "title": "複数ファイル送信",
    "sendDate": "2020-09-15T04:26:12.000Z",
    "downloadDeadline": "2020-09-22T14:59:59.000Z"
}
EOS
)
# echo $(echo $responseJson | jq '.iwsdfile') 2>&1$log
echo $responseJson | jq -r '.iwsdfile[].id' >> $log 2>&1
echo "Access ReceiveShow End" >> $log 2>&1
# ファイルID取得（仮）
# fileId="{iwsdfile:[:id]}"
fileId="1"
fileName="text.txt"
# 消すな！JSON形式読み込むコマンド
# echo $(echo $responseJson | jq '.filesCount') >> filesCount
# リクエストボディの定義
json=$(cat << EOS
{
    "receiverId" : ${mailId},
    "fileId" : ${fileId}
}
EOS
)
echo $responseJson | jq -r '.iwsdfile[].id' >> $fileId
for key in $(echo $responseJson | jq -r '.iwsdfile[].id'); do
    # ダウンロード API実行
    echo "Access download Start" >> $log 2>&1
# リクエストボディの定義
json=$(cat << EOS
{
    "receiverId" : ${mailId},
    "fileId" : ${key}
}
EOS
)
    echo $json >> $log 2>&1
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
          -d "$json">> $log 2>&1
    
    echo "Access download End" >> $log 2>&1
done
echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
