"""Reimport the managed glass resource through uBlock's API. Requires temporary Marionette."""
import pathlib,json,re,time,base64,hashlib
from marionette import Client
root=pathlib.Path(__file__).parent
c=Client();previous=c.cmd('WebDriver:GetWindowHandle')
c.cmd('Marionette:SetContext',{'value':'chrome'})
c.script("if(window.knightInstall){let s=window.knightInstall;gBrowser.removeTab(s.tab);if(s.previous.isConnected)gBrowser.selectedTab=s.previous;delete window.knightInstall;}")
c.cmd('Marionette:SetContext',{'value':'content'})
previous=c.cmd('WebDriver:GetWindowHandles')[0];c.cmd('WebDriver:SwitchToWindow',{'handle':previous})
handle=c.cmd('WebDriver:NewWindow',{'type':'tab'})['handle'];c.cmd('WebDriver:SwitchToWindow',{'handle':handle})
c.cmd('Marionette:SetContext',{'value':'chrome'})
# Find uBlock's current UUID rather than assuming its profile-specific address.
uuid=c.script("return WebExtensionPolicy.getByID('uBlock0@raymondhill.net').mozExtensionHostname")['value']
c.script("gBrowser.selectedBrowser.loadURI(Services.io.newURI(arguments[0]),{triggeringPrincipal:Services.scriptSecurityManager.getSystemPrincipal()})",['moz-extension://'+uuid+'/dashboard.html'])
c.cmd('Marionette:SetContext',{'value':'content'});time.sleep(.6)
def send(m):return c.script("let done=arguments[arguments.length-1];vAPI.messaging.send('dashboard',arguments[0]).then(done)",[m],True)['value']
old=send({'what':'readHiddenSettings'});filters=send({'what':'readUserFilters'})
backup=pathlib.Path.home()/'.local/state/firefox-glass'/('install-'+time.strftime('%Y%m%d-%H%M%S')+'.json');backup.parent.mkdir(parents=True,exist_ok=True);backup.write_text(json.dumps({'hidden':old,'filters':filters}))
resource=(root/'knight-glass.js').read_bytes();uri='data://text/plain;base64,'+base64.b64encode(resource).decode()+'#knight-glass'
hidden=dict(old['current']);existing=hidden['userResourcesLocation'];urls=[] if existing=='unset' else existing.split();urls=[u for u in urls if not u.endswith('#knight-glass')];hidden['userResourcesLocation']=' '.join(urls+[uri])
settings='\n'.join(k+' '+(str(v).lower() if isinstance(v,bool) else str(v)) for k,v in hidden.items())
send({'what':'writeHiddenSettings','content':settings});time.sleep(.4)
block='! BEGIN KNIGHT TINTED PAGE BACKGROUNDS\n*##+js(knight-glass)\n! END KNIGHT TINTED PAGE BACKGROUNDS'
content=re.sub(r'! BEGIN KNIGHT TINTED PAGE BACKGROUNDS\n.*?! END KNIGHT TINTED PAGE BACKGROUNDS','',filters['content'],flags=re.S).rstrip()+'\n'+block
send({'what':'writeUserFilters','enabled':filters['enabled'],'trusted':filters['trusted'],'content':content});send({'what':'reloadAllFilters'})
after=send({'what':'readHiddenSettings'})['current'];assert after==hidden
assert send({'what':'readUserFilters'})['content'].strip()==content.strip()
print('Installed source SHA256:',hashlib.sha256(resource).hexdigest()[:16]);print('Unrelated uBlock settings preserved.')
c.cmd('WebDriver:CloseWindow');c.cmd('WebDriver:SwitchToWindow',{'handle':previous})
