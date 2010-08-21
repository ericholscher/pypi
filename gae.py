# Helper for the mirror on GAE
# GAE GETs an action gae_file, giving GAE host and a secret
# PyPI GETs /mkupload/secret, learning path and upload session
# PyPI POSTs to upload session
import urllib2, httplib, threading, os, binascii, urlparse

POST="""\
--%(boundary)s
Content-Disposition: form-data; name="secret"

%(secret)s
--%(boundary)s
Content-Disposition: form-data; name="path"

%(path)s
--%(boundary)s
Content-Disposition: form-data; name="file"; filename="%(path)s"
Content-Type: application/octet-stream

%(data)s
--%(boundary)s
"""
POST = "\r\n".join(POST.splitlines())+"\r\n"

def doit(host, secret, srcdir):
    x = urllib2.urlopen('http://%s/mkupload/%s' % (host, secret))
    if x.code != 200:
        return
    path,url = x.read().splitlines()
    host, session = urlparse.urlsplit(url)[1:3]
    try:
        data = open(srcdir+"/"+path).read()
    except IOError, e:
        return
    boundary = ""
    while boundary in data:
        boundary = binascii.hexlify(os.urandom(10))
    body = POST % locals()
    if ':' in host:
        host, port = host.split(':')
    else:
        port = 80
    c = httplib.HTTPConnection(host, port)
    c.request('POST', session,
              headers = {'Content-type':'multipart/form-data; boundary='+boundary,
                         'Content-length':str(len(body)),
                         'Host':host},
              body=body)
    resp = c.getresponse()
    data = resp.read()
    # result code should be redirect
    c.close()

def transfer(host, secret, srcdir):
    secret = secret.encode('ascii')
    t = threading.Thread(target=doit, args=(host, secret, srcdir))
    t.start()
