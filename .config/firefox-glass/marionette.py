import socket,json,time
class Client:
 def __init__(self):
  self.s=socket.create_connection(('127.0.0.1',2828),10); self.s.settimeout(35); self.i=0; self.recv();self.cmd('WebDriver:NewSession',{'capabilities':{}})
 def recv(self):
  n=b''
  while True:
   c=self.s.recv(1)
   if c==b':':break
   if not c:raise RuntimeError('closed')
   n+=c
  b=b''
  while len(b)<int(n):
   chunk=self.s.recv(int(n)-len(b))
   if not chunk:raise RuntimeError('closed')
   b+=chunk
  return json.loads(b)
 def cmd(self,name,p=None):
  self.i+=1;b=json.dumps([0,self.i,name,p or {}]).encode();self.s.sendall(str(len(b)).encode()+b':'+b)
  r=self.recv()
  if r[2]:raise RuntimeError(r[2])
  return r[3]
 def script(self,s,args=None,async_=False):
  return self.cmd('WebDriver:ExecuteAsyncScript' if async_ else 'WebDriver:ExecuteScript',{'script':s,'args':args or [],'newSandbox':False,'sandbox':None})
