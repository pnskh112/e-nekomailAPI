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

# ここで、変数resにjqを使ってJSQN形式データを入力させる。
res=`echo '{ "statusCode": 429, "message": "Rate limit is exceeded.", "Retry-After": 1 }' | jq '.'`
#res=`echo '{    "replyDeadline": "2018-12-30T23:59:59.000Z",    "comment": "test mail",    "iwsdfile": [        {            "downloadCount": 3,            "id": 9707,            "fileName": "test.jpg",            "fileSize": 561276        }    ],    "senderMailAddress": "tarou.fuji@xxx.xxx",    "filesCount": 1,    "iwsdreceiver": [        {            "id": 21710,            "status": "NOT_READ",            "addressType": "To",            "mailAddress1": "hanako.fuji@xxx.xxx"        }    ],    "repositoryType": 0,    "title": "test mail",    "sendDate": "2018-10-03T12:00:00.000Z",    "downloadDeadline": "2018-10-10T23:59:59.000Z"}' | jq '.'`

# 下記のように、Json返すAPIを呼び出して
#res=`curl  -X POST "$requesturi/sdms/mails/inbox/" \
#      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#      -H "Content-Type: application/json" \
#      -d @- << EOF | jq
#{
#    "inboxMailStatus": "NOT_READ",
#     "sendDateFrom": "${date_ymd}T00:00:00.000Z",
#     "sendDateTo": "${date_ymd}T23:59:59.000Z",
#     "skip": 0,
#     "take": 1
#}
#EOF
`

echo "start"

# 変数resに対して、JSON形式で値の存在チェックや内容チェックなどを行い、引っかかればErrorIsOccuredと出力させる。
if [[  $( echo $res | jq 'select(contains({ statusCode: 429 }))') ]]; then
    echo "Error Is Occured!!!!"
    exit 9
fi
    echo ${res} >> $log 2>&1
    echo "===" >> $log 2>&1
    echo "Access ReceiveShow End" >> $log 2>&1


echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
exit 0

