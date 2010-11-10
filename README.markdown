Twig - A hackable api-powered blogging engine in Sinatra
=========

Frustrated by static generators that couldn't (easily) be used with desktop blog editing software and dreading more full-featured blog packages, I hacked on Erik Kastner's [sin blogging engine](https://github.com/kastner/sin) experiment to add some basic user authentication, bring it up to date with Sinatra and wrap the whole thing in Mongo and Rails3-mountable goodness.

This currently powers the blog for Montabe at [http://montabe.com/blog](http://montabe.com/blog)

What it doesn't do
----------------

* It does not include any administration UI screens or functionality. You do everything via the API and the blog editing software of your choice. My recommendation: [MarsEdit](http://www.red-sweater.com/marsedit/) (Mac only)

* It doesn't do comments. But you're free to add [Disqus](http://disqus.com/), [Intense Debate](http://intensedebate.com/) or whatever you'd like

* It doesn't do tags, categories or any of that other fancy-schamncy blog type stuff. It's just posts.

Requirements
----------------

* [sinatra](https://github.com/sinatra/sinatra)

* [mongoid](https://github.com/mongoid/mongoid)

* [mongoid_slug](https://github.com/papercavalier/mongoid-slug)

* [RDiscount](https://github.com/rtomayko/rdiscount)

Getting started
----------------

To get up and running, first you're going to need a mongo database somewhere to point to. It can be local or remote (for remote, I recommend [MongoHQ](https://mongohq.com/home)). Just edit the included mongoid.yml with your connection info and credentials (if you're doing authenticated Mongo).

Next up, you'll need a users file. I've included one in twig_users.yml, but make for damn sure you change the user credentials before you deploy to anything resembling a production environment. It can support as many users as you'd like (the file currently has two).

There's a config.ru for your convenience. Feel free to edit as needed.

Mounting in a Rails 3 app
----------------

Here's how I do it, feel free to do it however you'd like:

* Put twig.rb and the views and public folders into your Rails app's lib folder.

* Put the mongoid.yml file in your Rails app's config directory (or better yet, just use your app's mongoid.yml file). Do the same for twig_users.yml.

* Change line 10 to: file_name =  File.dirname(__FILE__) + "/../config/mongoid.yml"

* Change line 127 to: file_name =  File.dirname(__FILE__) + "/../config/twig_users.yml"

* Add a require for twig to your app's application.rb file. BONUS TIP: If you're using Ruby 1.9, here's what you'll need: require File.expand_path("../../lib/twig", __FILE__)

* Edit your routes file to include: mount Twig => "/blog" (or wherever you'd like to have it mounted)

* Final step: Change the BASE_URL constant (line 22) to the actual base url of your blog (minus the trailing slash)

TODO
----------------

That Rails3 mounting bit is obviously entirely too difficult. Down the road, this will convert to a gem that includes some generators to handle a lot of this for you.

It's also obviously lacking a few features I'd like to have: an Atom feed and the ability to delete a post most notably.

