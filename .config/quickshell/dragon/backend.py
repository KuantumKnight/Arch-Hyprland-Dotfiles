#!/usr/bin/python
"""Local dock service bridge. Arguments are arrays, never shell commands."""
import json,subprocess,threading,time,sys,pathlib,dbus,queue
bus=dbus.SessionBus(); system=dbus.SystemBus(); lock=threading.Lock(); dnd_cookie=None; message=''
def run(*args):
 p=subprocess.run(args,capture_output=True,text=True,timeout=12)
 if p.returncode: raise RuntimeError((p.stderr or p.stdout).strip()[-250:])
 return p.stdout.strip()
def safe(*args):
 try:return run(*args)
 except Exception:return ''
def interface(service,path,name):
 # Optional services must not hold up every control while D-Bus tries to start them.
 if not bus.name_has_owner(service):raise RuntimeError(service+' is not running')
 return dbus.Interface(bus.get_object(service,path,introspect=False),name)
def bright():
 # Plasma 6 exposes displays through ScreenBrightness; prefer the internal panel.
 service='org.kde.ScreenBrightness'; path='/org/kde/ScreenBrightness'
 displays=props(service,path,service)['DisplaysDBusNames']
 candidates=[]
 for name in displays:
  display_path=path+'/'+str(name)
  p=props(service,display_path,service+'.Display')
  if int(p['MaxBrightness'])>0:candidates.append((display_path,p))
 if not candidates:raise RuntimeError('No controllable display brightness found')
 display_path,p=next((d for d in candidates if d[1].get('IsInternal')),candidates[0])
 return interface(service,display_path,service+'.Display'),int(p['Brightness']),int(p['MaxBrightness'])
def brightness():
 try:
  _,value,maximum=bright()
  return round(100*value/maximum)
 except Exception:return -1
def props(service,path,iface):return interface(service,path,'org.freedesktop.DBus.Properties').GetAll(iface)
last_emitted={}
def emit(value):
 with lock:
  changed={k:v for k,v in value.items() if k not in last_emitted or last_emitted[k]!=v}
  if not changed:return
  last_emitted.update(changed)
  print(json.dumps(changed),flush=True)
def battery_status(power_root=pathlib.Path('/sys/class/power_supply')):
 batteries=[];external_power=False
 for supply in sorted(power_root.glob('*')):
  try:
   kind=(supply/'type').read_text().strip()
   if kind=='Battery':
    if (supply/'scope').exists() and (supply/'scope').read_text().strip()=='Device':continue
    if (supply/'present').exists() and (supply/'present').read_text().strip()=='0':continue
    batteries.append(dict(level=max(0,min(100,int((supply/'capacity').read_text()))),status=(supply/'status').read_text().strip()))
   elif (supply/'online').exists():external_power|=(supply/'online').read_text().strip()=='1'
  except (OSError,ValueError):continue
 if not batteries:return None
 battery=batteries[0]
 battery['externalPower']=external_power or battery['status']=='Charging'
 return battery
def state():
 global message
 wifi=safe('nmcli','radio','wifi')=='enabled'; networks=[]; seen=set()
 for line in safe('nmcli','-t','--escape','no','-f','ACTIVE,SSID,SIGNAL,SECURITY','device','wifi','list','--rescan','no').splitlines():
  try:
   active,rest=line.split(':',1); ssid,signal,security=rest.rsplit(':',2)
   if not ssid:continue
   if ssid in seen:
    if active=='yes':
     for n in networks:
      if n['name']==ssid:n['active']=True
    continue
   seen.add(ssid); networks.append(dict(name=ssid,active=active=='yes',signal=int(signal),security=security))
  except ValueError:pass
 volume=safe('wpctl','get-volume','@DEFAULT_AUDIO_SINK@'); sinks=[]
 try:
  for item in json.loads(run('pw-dump')):
   p=item.get('info',{}).get('props',{})
   if p.get('media.class')=='Audio/Sink':sinks.append(dict(id=item['id'],name=p.get('node.description',p.get('node.name','Audio'))))
 except Exception:pass
 bt=safe('bluetoothctl','show'); devices=[]
 for line in safe('bluetoothctl','devices').splitlines():
  parts=line.split(' ',2)
  if len(parts)==3:devices.append(dict(address=parts[1],name=parts[2],connected='Connected: yes' in safe('bluetoothctl','info',parts[1])))
 battery=battery_status()
 display_brightness=brightness()
 try: night=props('org.kde.KWin','/org/kde/KWin/NightLight','org.kde.KWin.NightLight'); night_on=bool(night['enabled']); night_available=bool(night['available'])
 except Exception:night_on=False;night_available=False
 try:
  dnd=bool(props('org.freedesktop.Notifications','/org/freedesktop/Notifications','org.freedesktop.Notifications')['Inhibited']);dnd_available=True
 except Exception:dnd=False;dnd_available=False
 players=[]
 for name in bus.list_names():
  if name.startswith('org.mpris.MediaPlayer2.'):
   try:
    p=props(name,'/org/mpris/MediaPlayer2','org.mpris.MediaPlayer2.Player'); m=p['Metadata']; players.append(dict(service=str(name),title=str(m.get('xesam:title','Media')),playing=p['PlaybackStatus']=='Playing',control=bool(p.get('CanControl',False))))
   except Exception:pass
 default_sink=__import__('re').search(r'id (\d+)',safe('wpctl','inspect','@DEFAULT_AUDIO_SINK@'))
 profile_list=safe('powerprofilesctl','list')
 return dict(wifi=wifi,networks=sorted(networks,key=lambda x:(not x['active'],-x['signal'])),volume=float(volume.split()[1]) if volume else 0,mute='MUTED' in volume,sinks=sinks,defaultSink=int(default_sink.group(1)) if default_sink else -1,bluetooth='Powered: yes' in bt,bluetoothAvailable=bool(bt),devices=devices,battery=battery,brightness=display_brightness,profile=safe('powerprofilesctl','get'),profiles=[x for x in ['power-saver','balanced','performance'] if x+':' in profile_list],night=night_on,nightAvailable=night_available,dnd=dnd,dndAvailable=dnd_available,players=players,message=message)
def action(a):
 global message,dnd_cookie
 try:
  k=a['action']; v=a.get('value')
  if k=='wifi':run('nmcli','radio','wifi','on' if v else 'off')
  elif k=='scan':run('nmcli','device','wifi','rescan')
  elif k=='connect':
   known=safe('nmcli','-t','--escape','no','-f','NAME','connection','show').splitlines()
   if v in known:run('nmcli','connection','up','id',v)
   else:
    # Plasma handles WPA/enterprise credentials without keeping secrets here.
    subprocess.Popen(['kcmshell6','kcm_networkmanagement'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    message='Select '+v+' in the opened network settings to enter credentials.'
  elif k=='bluetooth':run('bluetoothctl','power','on' if v else 'off')
  elif k=='btscan':run('bluetoothctl','--timeout','8','scan','on')
  elif k=='btconnect':
   if 'Paired: yes' not in safe('bluetoothctl','info',v):run('bluetoothctl','pair',v)
   run('bluetoothctl','connect',v)
  elif k=='btdisconnect':run('bluetoothctl','disconnect',v)
  elif k=='btsetup':subprocess.Popen(['bluedevil-wizard'])
  elif k=='volume':run('wpctl','set-volume','-l','1.0','@DEFAULT_AUDIO_SINK@',str(max(0,min(1,float(v)))))
  elif k=='mute':run('wpctl','set-mute','@DEFAULT_AUDIO_SINK@','toggle')
  elif k=='output':run('wpctl','set-default',str(int(v)))
  elif k=='brightness':
   display,_,maximum=bright()
   display.SetBrightness(int(maximum*max(1,min(100,float(v)))/100),dbus.UInt32(0))
  elif k=='profile':run('powerprofilesctl','set',v)
  elif k=='night':
   run('kwriteconfig6','--notify','--file','kwinrc','--group','NightColor','--key','Active','true' if v else 'false');interface('org.kde.KWin','/KWin','org.kde.KWin').reconfigure()
  elif k=='dnd':
   n=interface('org.freedesktop.Notifications','/org/freedesktop/Notifications','org.freedesktop.Notifications')
   if v:dnd_cookie=n.Inhibit('org.quickshell.dock','Dock Do Not Disturb',dbus.Dictionary({},signature='sv'))
   elif dnd_cookie is not None:n.UnInhibit(dnd_cookie);dnd_cookie=None
   else:message='Do Not Disturb is enabled by another application.'
  elif k=='media':getattr(interface(a['service'],'/org/mpris/MediaPlayer2','org.mpris.MediaPlayer2.Player'),v)()
  if k not in ('connect','dnd'):message=''
 except Exception as e:message=str(e)[-250:]
commands=queue.Queue()
def stdin():
 for line in sys.stdin:
  try:commands.put(json.loads(line))
  except Exception:pass
threading.Thread(target=stdin,daemon=True).start()
def levels():
 value=safe('wpctl','get-volume','@DEFAULT_AUDIO_SINK@')
 out={'message':message}
 if value:
  out.update(volume=float(value.split()[1]),mute='MUTED' in value)
 out['brightness']=brightness()
 return out
next_poll=0
while True:
 batch=[]
 try:
  batch.append(commands.get(timeout=max(0.01,next_poll-time.monotonic())))
  while True:batch.append(commands.get_nowait())
 except queue.Empty:pass
 # Coalesce slider motion so older positions never delay the final value.
 last={a['action']:i for i,a in enumerate(batch) if a.get('action') in ('volume','brightness')}
 for i,a in enumerate(batch):
  k=a.get('action')
  if k in last and last[k]!=i:continue
  action(a)
  try:emit(levels())
  except Exception as e:emit({'message':str(e)})
  if k not in ('volume','brightness','mute'):next_poll=0
 if time.monotonic()>=next_poll:
  try:emit(state())
  except Exception as e:emit({'message':str(e)})
  next_poll=time.monotonic()+3
