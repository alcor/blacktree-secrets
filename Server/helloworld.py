import cgi
import wsgiref.handlers
import os

from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template

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
  bundle = db.StringProperty()
  display_bundle = db.StringProperty()
  app_reference = db.ReferenceProperty(Bundle)
  keypath = db.StringProperty()
  datatype = db.StringProperty()
  title = db.StringProperty()
  defaultvalue = db.StringProperty()
  units = db.StringProperty()
  widget = db.StringProperty()
  username = db.StringProperty()
  hostname = db.StringProperty()
  minversion = db.StringProperty()
  maxversion = db.StringProperty()
  minosversion = db.StringProperty()
  maxosversion = db.StringProperty()
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
  deleted = db.BooleanProperty()
  is_broken = db.BooleanProperty()
  dangerous = db.BooleanProperty()
  
  created_at = db.DateTimeProperty(auto_now_add=True)
  updated_at = db.DateTimeProperty(auto_now=True)
  
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
    exclude = ['author', 'editor', 'app_reference', 'deleted', 'old_id']
    
class PlistSecret(webapp.RequestHandler):
  def get(self):
    secrets = Secret.all().order('-created_at')

    if users.get_current_user():
      url = users.create_logout_url(self.request.uri)
      url_linktext = 'Logout'
    else:
      url = users.create_login_url(self.request.uri)
      url_linktext = 'Login'

    template_values = {
      'secrets': secrets,
      'url': url,
      'url_linktext': url_linktext,
      }
    
    self.response.headers['Secrets-Version'] = "1.0.2"
    self.response.headers['Content-Type'] = 'text/xml; charset=utf-8'
    self.response.out.write(template.render('plist.xml', template_values))

class MainPage(webapp.RequestHandler):
  def get(self):
    secrets = Secret.all().order('-created_at')

    if users.get_current_user():
      url = users.create_logout_url(self.request.uri)
      url_linktext = 'Logout'
    else:
      url = users.create_login_url(self.request.uri)
      url_linktext = 'Login'

    template_values = {
      'secrets': secrets,
      'url': url,
      'url_linktext': url_linktext,
      }

    path = os.path.join(os.path.dirname(__file__), 'index.html')
    self.response.out.write(template.render('index.html', template_values))
    
class NewSecret(webapp.RequestHandler):
  def get(self):
    self.response.out.write(template.render('form.html', {'form':SecretForm()}))

  def post(self):
    data = SecretForm(data = self.request.POST)
    if data.is_valid():
      # Save the data, and redirect to the view page
      entity = data.save(commit=False)
      entity.editor = users.get_current_user()
      entity.put()
      self.redirect('/')
    else:
      self.response.out.write(template.render('form.html', {'form':data}))
      # Reprint the form

class EditSecret(webapp.RequestHandler):
  def get(self):
    id = int(self.request.get('id'))
    item = Secret.get(db.Key.from_path('Secret', id))
    self.response.out.write(template.render('form.html', {'form':SecretForm(instance=item), 'id':id}))

  def post(self):
    id = int(self.request.get('_id'))
    item = Secret.get(db.Key.from_path('Secret', id))
    data = SecretForm(data=self.request.POST, instance=item)
    if data.is_valid():
      # Save the data, and redirect to the view page
      entity = data.save(commit=False)
      entity.added_by = users.get_current_user()
      entity.put()
      self.redirect('/items.html')
    else:
      # Reprint the form
      self.response.out.write(template.render('form.html', {'form':data, 'id':id}))
class PurgeSecret(webapp.RequestHandler):
  def get(self):
    results = Secret.all();
    for result in results:
      result.delete() 
                                                                               
def main():
  application = webapp.WSGIApplication(
                                       [('/new', NewSecret),
                                        ('/edit', EditSecret),
                                        ('/plist', PlistSecret),
                                        ('/purge', PurgeSecret),
                                        ('/', MainPage)],
                                       debug=True)
  wsgiref.handlers.CGIHandler().run(application)

if __name__ == "__main__":
  main()