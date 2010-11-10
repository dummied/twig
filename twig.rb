# A minimal sinatra blog engine powered via the MetaWeblogAPI and geared toward use with Mongoid and mounted in a Rails 3 application (though it'll work standalone as well). Based on original work by Erik Kastner.

require 'rubygems'
require 'sinatra/base'
require 'xmlrpc/marshal'
require 'mongoid'
require 'mongoid_slug'
require 'rdiscount'

file_name =  File.dirname(__FILE__) + "/mongoid.yml"
@settings = YAML.load(ERB.new(File.new(file_name).read).result)

Mongoid.configure do |config|
  config.from_hash(@settings[ENV["RAILS_ENV"] || "development"])
end

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  BASE_URL = "http://your_primary_url_here_as_in_what_the_post_slug_should_hang_off_minus_the_trailing_slash.com"
  
  field :title
  field :author
  field :description
  
  slug :title, :permanent => true
  
  def permalink; "/posts/#{to_param}"; end
  def full_permalink; BASE_URL + permalink; end
  
  def to_metaweblog
    {
      :dateCreated => created_at,
      :userid => 1,
      :postid => id.to_s,
      :description => description,
      :title => title,
      :link => "#{full_permalink}",
      :permaLink => "#{full_permalink}",
      :categories => ["General"],
      :date_created_gmt => created_at.getgm,
    }
  end
  
  def to_param
    slug
  end
end

class Twig < Sinatra::Base
  
  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'

  get '/' do
    @posts = Post.order_by(["created_at", "DESC"]).paginate(:page => params[:page] || 1)
    erb :index
  end


  get '/posts/:id' do
    @post = Post.where(:slug => params[:id]).first
    @title = @post.title
    erb :show
  end


  # metaweblog api handler
  post '/xml' do
    xml = @request.env["rack.input"]
    if (xml == nil) || xml.blank?
      hash = @request.env["rack.request.query_hash"]
      xml = (hash.keys + hash.values).join
    end
  
    raise "Nothing supplied" if xml == nil
    call = XMLRPC::Marshal.load_call(xml)
    # convert metaWeblog.getPost to get_post
    if users.detect{|user| user.name == call[1][1]} && users.select{|user| user.name == call[1][1]}.first.password == call[1][2]
      method = call[0].gsub(/metaWeblog\.(.*)/, '\1').gsub(/([A-Z])/, '_\1').downcase
  
      headers 'Content-Type' => 'text/xml'  
      send(method, call)
    end
  end

  def get_post(xmlrpc_call)
    begin
      post = Post.find(xmlrpc_call[1][0])
    rescue ActiveRecord::RecordNotFound
      post = Post.find(xmlrpc_call[1][0].gsub(/^.*posts\/(\d+)[^\d].*$/, '\1'))
    end
    XMLRPC::Marshal.dump_response(post.to_metaweblog)
  end

  def get_recent_posts(xmlrpc_call)
    posts = Post.order_by(["created_at", "DESC"]).limit(10).all
    XMLRPC::Marshal.dump_response(posts.map{|p| p.to_metaweblog})
  end

  def new_post(xmlrpc_call)
    data = xmlrpc_call[1]
    # blog_id = data[0]; user = data[1]; pass = data[2]
    post_data = data[3]
    post = Post.create(:author => data[1], :title => post_data["title"], :description => post_data["description"])
    puts post.to_metaweblog.inspect
    XMLRPC::Marshal.dump_response(post.to_metaweblog)
  end

  def edit_post(xmlrpc_call)
    data = xmlrpc_call[1]
    post = Post.find(data[0])
    # user = data[1]; pass = data[2]
    post_data = data[3]
    post.update_attributes!(:title => post_data["title"], :description => post_data["description"])
    XMLRPC::Marshal.dump_response(post.to_metaweblog)
  end

  def get_categories(xmlrpc_call)
    res = [{ :categoryId => 1,:parentId => 0,:description => "General",:categoryName => "General",:htmlUrl => "http://test.com/categories/1",:rssUrl => "http://test.com/categories/1/feed"}]
    XMLRPC::Marshal.dump_response(res)
  end

  def users
    unless @users
      file_name =  File.dirname(__FILE__) + "/twig_users.yml"
      @users = YAML.load(File.new(file_name).read).collect{|user| OpenStruct.new(user[1])}
    end
    return @users
  end
  
  def twig_truncate(text, length = 30, truncate_string = " ...")
    return if text.nil?
    l = length - truncate_string.length
   text.length > l ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end
  
  def paginate(objects, page)
    if objects.total_pages > 1
      starter = "<ul>"
      unless objects.previous_page.nil?
        starter << "<li class=\"previous\"><a href=\"?page=#{objects.previous_page}\">Earlier</a></li>"
      end
      unless objects.next_page.nil?
        starter << "<li class=\"next\"><a href=\"?page=#{objects.next_page}\">Later</a></li>"
      end
      starter << "</ul>"
      return starter
    end
  end
end