import cgi
import wsgiref.handlers
import os
import datetime
from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template
from google.appengine.api import memcache
from google.appengine.ext.db import djangoforms

import xml.etree.cElementTree as ET

class Bundle(db.Model):
  bundle_id = db.StringProperty()
  name = db.StringProperty()
  icon = db.LinkProperty()


DATA_TYPES = (
("Boolean", "boolean"),
("Boolean (Negate)", "boolean-neg"),
("Integer", "integer"),
("Float", "float"),
("String", "string"),
("Bundle Identifier", "bundleid"),
("Font Name", "font"),
("File Path", "path"),
("Rect", "rect"),
("Array", "array"),
("Array (Add)", "array-add"),
("Array (Multi Add)", "array-add-multiple"),
("Dictionary", "dict"),
("Dictionary (Add)", "dict-add"),
("Date", "date"),
("Color", "color"),
("URL", "url")
)
  
class Secret(db.Model):
  author = db.UserProperty()
  editor = db.UserProperty()
  
  old_id = db.IntegerProperty()
  bundle = db.StringProperty(verbose_name="Bundle ID")
  display_bundle = db.StringProperty()
  app_reference = db.ReferenceProperty(Bundle)
  keypath = db.StringProperty(verbose_name="Key")
  datatype = db.StringProperty()
  title = db.StringProperty()
  defaultvalue = db.StringProperty(verbose_name="Default Value")
  units = db.StringProperty()
  widget = db.StringProperty()
  username = db.StringProperty()
  hostname = db.StringProperty()
  minversion = db.StringProperty(verbose_name="Min Version")
  maxversion = db.StringProperty(verbose_name="Max Version")
  minosversion = db.StringProperty(verbose_name="Min OS Version")
  maxosversion = db.StringProperty(verbose_name="Max OS Version")
  group = db.StringProperty()
  placeholder = db.StringProperty()
  
  values = db.StringProperty(multiline=True)
  description = db.StringProperty(multiline=True)
  notes = db.StringProperty(multiline=True)
  
  hidden = db.BooleanProperty()
  verified = db.BooleanProperty()
  current_host_only = db.BooleanProperty()
  set_for_all_users = db.BooleanProperty()
  has_ui = db.BooleanProperty()
  for_developers = db.BooleanProperty()
  top_secret = db.BooleanProperty()
  is_keypath = db.BooleanProperty()
  deleted = db.BooleanProperty(default=False)
  is_broken = db.BooleanProperty()
  dangerous = db.BooleanProperty()
  
  created_at = db.DateTimeProperty(auto_now_add=True)
  updated_at = db.DateTimeProperty(auto_now=True)
  
  def is_editable(self):
    return (datetime.datetime.today() - self.created_at) < datetime.timedelta(minutes=3)
    
  def default_string(self):
    valid = True
    
    if self.is_keypath:
      valid = False
    
    termbundle = self.bundle
    if self.set_for_all_users:
      termbundle = "/Library/Preferences/" + termbundle;
   
    if self.bundle == ".GlobalPreferences":
       termbundle = "-g"
    
    if valid:
      default_string = "defaults "
      
      if (self.current_host_only):
        default_string += "-currentHost "
        
      default_string += "write " + termbundle + " " + self.keypath + " [" + self.datatype + "]"
      return default_string;
    else:
      return termbundle + " " + self.keypath + " [" + self.datatype + "]"
  
  def remove_string(self):
    return "defaults delete " + bundle + " " + keypath
  
  def display_title(self):
    title = self.title

    if title.length == 0:
      title = "(untitled)"
    
    return title
    
  def display_icon(self):
      if self.display_bundle:
        return self.display_bundle
      return self.bundle
      
  def display_app(self):
    bundle = self.bundle
    if bundle:
      bundle = bundle.split('.')[-1]
  
    display_bundle = self.display_bundle
    # if display_bundle:
    #   if (len(display_bundle) > 0):
    #     icon = self.display_bundle
    #     icon = icon.split('/').last
    
 
    # if (display_bundle == "prefPane" | display_bundle == "editor"  | display_bundle == "bundle" | display_bundle == "launcher"):
    #    # display_bundle = self.display_bundle.split('.')[-2]
    #    display_bundle = self.display_bundle.split('/')[-1]
    #   
    if bundle == "GlobalPreferences":
      bundle = "Every App"
  
    if bundle == "kCFPreferencesAnyApplication":
      bundle = "Any App"
      
    if self.display_bundle:
      bundle = display_bundle.split('.')[-1]
    return bundle
    #  def put_value (key, type, xml)
    # 
    #     value = eval "self." + key
    #     if (value)
    #         xml.key(key)
    #         xml.string(value)
    #       end
    # end
    
class SecretForm(djangoforms.ModelForm):
  class Meta:
    model = Secret
    exclude = ['hostname', 'username', 'author', 'editor', 'app_reference', 'deleted', 'top_secret', 'old_id']
    
class PlistSecret(webapp.RequestHandler):
  def get(self):
    secrets = Secret.all().order('-created_at')

    template_values = {
      'secrets': secrets    
      }
    
    self.response.headers['Secrets-Version'] = "1.0.4"
    self.response.headers['Content-Type'] = 'text/xml; charset=utf-8'
    output = memcache.get("plist")
    if output is None:
      output = template.render('plist.xml', template_values)
      memcache.add("plist", output)
      self.response.headers['Cached'] = 'yes'
    self.response.out.write(output)

class MainPage(webapp.RequestHandler):
  def get(self):
    query = Secret.all()
    
    showall = self.request.get('show') == 'all'
    showrecent = self.request.get('show') == 'recent'
    cachename = "index-" + self.request.get('show')
    
    output = memcache.get(cachename)
    if output is not None:
      self.response.out.write(output)
      self.response.out.write("<!--loaded from cache-->")
      #self.response.out.write(memcache.get_stats())
    else:
      query.filter('deleted ==', False)
      if showrecent == True:
        query = db.GqlQuery("SELECT * FROM Secret WHERE deleted = False "
                            "ORDER BY created_at DESC")
        secrets = query.fetch(10)
      elif showall == True:
        query = db.GqlQuery("SELECT * FROM Secret WHERE deleted = False "
                              "ORDER BY created_at DESC")
        secrets = query
      else:
        query.filter('top_secret =', True)
        secrets = query
      
      template_values = {'secrets': secrets, 'showall': showall}
      
      path = os.path.join(os.path.dirname(__file__), 'index.html')
      output = template.render('index.html', template_values)
      memcache.add(cachename, output) 
      self.response.out.write(output)
    
class DeleteSecret(webapp.RequestHandler):
  def post(self):
    id = self.request.get('_id') 
    item = Secret.get(db.Key.from_path('Secret', int(id)))
    item.deleted = True
    item.put()
    self.redirect('/')
    
class EditSecret(webapp.RequestHandler):
  def get(self):
    if users.get_current_user():
      url = users.create_logout_url(self.request.uri)
      loggedin = 1
    else:
      url = users.create_login_url(self.request.uri)
      loggedin = 0
    isadmin = users.is_current_user_admin()
    id = self.request.get('id')
    template_values = {
      'id':id,
      'isadmin':isadmin,
      'loggedin':loggedin,
      'url': url
    }
    if id:
      item = Secret.get(db.Key.from_path('Secret', int(id)))
      isowned = (item.author != None) & (item.author == users.get_current_user());
      template_values['isowned'] = isowned
      template_values['iseditable'] = isadmin | isowned | (item.is_editable() & loggedin)
      template_values['form'] = SecretForm(instance=item)
      template_values['secret'] = item
    else:
      template_values['form'] = SecretForm()
      template_values['iseditable'] = loggedin
      
    self.response.out.write(template.render('form.html', template_values))
  
  def post(self):
    id = self.request.get('_id') 
    
    if id:
      item = Secret.get(db.Key.from_path('Secret', int(id)))
      data = SecretForm(data=self.request.POST, instance=item)
    else:
      data = SecretForm(data = self.request.POST)
    
    if data.is_valid():
      # Save the data, and redirect to the view page
      entity = data.save(commit=False)
      if not id:
          entity.author = users.get_current_user()
      entity.editor = users.get_current_user()
      entity.put()
      self.redirect('/')
      memcache.flush_all()
    else:
      # Reprint the form
      if id:
        self.response.out.write(template.render('form.html', {'form':data, 'id':id}))
      else:
        self.response.out.write(template.render('form.html', {'form':data}))
      
class PurgeSecrets(webapp.RequestHandler):
  def get(self):
    results = Secret.all();
    for result in results:
      result.delete() 
     

class RSSNewSecret(webapp.RequestHandler):
  def get(self):    
    output = memcache.get("rss-new")
    if output is None:
      secrets = Secret.all().order('-created_at').fetch(10)
      output = template.render("rss.xml", {'secrets':secrets})
      memcache.add("rss-new", output)

    self.response.headers['Content-Type'] = 'text/rss+xml; charset=utf-8'      
    self.response.out.write(output)
    
class RSSUpdatedSecret(webapp.RequestHandler):
  def get(self):
    output = memcache.get("rss-updated")
    if output is None:
      secrets = Secret.all().order('-updated_at').fetch(10)
      output = template.render("rss.xml", {'secrets':secrets})
      memcache.add("rss-updated", output)
   
    self.response.headers['Content-Type'] = 'text/rss+xml; charset=utf-8'
    self.response.out.write(output)
                                                                          
def main():
  application = webapp.WSGIApplication(
                                       [('/rss/updated', RSSUpdatedSecret),
                                        ('/rss/new', RSSNewSecret),
                                        ('/delete',DeleteSecret),
                                        ('/edit', EditSecret),
                                        ('/plist', PlistSecret),
                                        ('/purge', PurgeSecrets),
                                        ('/', MainPage)],
                                       debug=True)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == "__main__":
  main()