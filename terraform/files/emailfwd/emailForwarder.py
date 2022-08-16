"""
This code is a Python 3.6 port of [aws-lambda-ses-forwarder](https://github.com/arithmetric/aws-lambda-ses-forwarder). Follow instructions there for setting up SES and AWS Lambda. It was ported to py2.7 by [skylander86](https://gist.github.com/skylander86/d75bf010c7685bd3f951d2b6c5a32e7b), and then I added the following:

- py3 compatability, obviously.
- MSG_TARGET and MSG_TO_LIST: move the distribution list out of code.
- SUBJECT_PREFIX: add something like `[listname]` to the subject line.
- S3_PREFIX: an optional prefix for the key used to fetch a mail message. Useful if you put your incoming mail in an s3 'directory'.
- Commented out 'from rewriting', instead using 'reply-to' to redirect replies back to the list.

The original was MIT licensed; skylander86's gist doesn't have a license, so it is presumed to still be MIT. This version is copyright 2018 tedder, MIT license.
"""

import email
import json
import os

import boto3
from botocore.exceptions import ClientError

def getMappings():
    mappings = {}
    recips = os.getenv('RECIPS')
    fwds = os.getenv('FWDS')
    recips = recips.split(',')
    fwds = fwds.split(',')
    for src, dest in zip(recips, fwds):
        src = src.replace('"','').strip()
        dest = dest.replace('"','').strip()
        mappings.update({src: dest})
    return mappings


def lambda_handler(event, context):

    mappings = getMappings()

    verif_mail = os.getenv('VERIFIED_FROM_EMAIL', default='noreply@example.com')  # An email that is verified by SES to use as From address.
    subjprefix = os.getenv('SUBJECT_PREFIX') # label to add to a list, like `[listname]`
    incoming_bucket = os.getenv('SES_INCOMING_BUCKET')  # S3 bucket where SES stores incoming emails.
    recprefix = os.getenv('S3_PREFIX', default='') # optional, if messages aren't stored in root

    s3 = boto3.client('s3')
    ses = boto3.client('ses')

    record = event['Records'][0]
    if record['eventSource'] != 'aws:ses':
        return 

    print(f"messageId is {record['ses']['mail']['messageId']}")
    fname = recprefix + record['ses']['mail']['messageId']
    o = s3.get_object(Bucket=incoming_bucket, Key=fname)
    raw_mail = o['Body'].read()
    #print("body: {}".format(type(raw_mail)))
    #msg = raw_mail
    msg = email.message_from_bytes(raw_mail)
    #print("m: {}".format(msg))

    orig_from = msg['From'] # preserve this so we can reply-to it

    del msg['DKIM-Signature']
    del msg['Sender']
    del msg['Return-Path']
    del msg['Reply-To']
    del msg['From']

    print("keys: {}".format(msg.keys()))
    #original_from = msg['From']
    #del msg['From']
    #msg['From'] = re.sub(r'\<.+?\>', '', original_from).strip() + ' <{}>'.format(VERIFIED_FROM_EMAIL)

    msg['Reply-To'] = orig_from
    msg['From'] = verif_mail
    msg['Return-Path'] = verif_mail

    print("subject prefix: {}".format(subjprefix))
    if subjprefix and subjprefix.lower() not in msg.get('Subject').lower():
        new_subj = ' '.join([subjprefix, msg.get('Subject', '')])
        del msg['Subject']
        msg['Subject'] = new_subj
        print("new subj: {}".format(msg['Subject']))

    msg_string = msg.as_string()

    for recipient in record['ses']['receipt']['recipients']:
        print("recipient: {}".format(recipient))
        forwards = mappings.get(recipient, '')
        if not forwards:
            print('Recipent <{}> is not found in forwarding map. Skipping recipient.'.format(recipient))
            continue

        for address in forwards.split(','):
            print("addr: {}".format(address))

            try:
                o = ses.send_raw_email(Destinations=[address], RawMessage=dict(Data=msg_string))
                print('Forwarded email for <{}> to <{}>. SendRawEmail response={}'.format(recipient, address, json.dumps(o)))
            except ClientError as e: print('Client error while forwarding email for <{}> to <{}>: {}'.format(recipient, address, e))


if __name__ == '__main__':
    with open('testEvent.json', 'r') as inf:
        event = json.load(inf)

    context=None
    lambda_handler(event, context)
