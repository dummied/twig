xml.instruct! :xml, :version => '1.0', :encoding => 'utf-8'
xml.feed :'xml:lang' => 'en-US', :xmlns => 'http://www.w3.org/2005/Atom' do
  xml.id "http://#{Post::BASE_URL}"
  xml.link :type => 'text/html', :href => "http://#{Post::BASE_URL}", :rel => 'alternate'
  xml.link :type => 'application/atom+xml', :href => "http://#{Post::BASE_URL}/feed", :rel => 'self'
  xml.title "Twig" 
  xml.subtitle "#{h(Post::BASE_URL)}"
  xml.updated(@posts.first ? rfc_date(@posts.first.updated_on) : rfc_date(Time.now.utc))
  @posts.each do |post|
    xml.entry do |entry|
      entry.id post.full_permalink
      entry.link :type => 'text/html', :href => post.full_permalink, :rel => 'alternate'
      entry.updated rfc_date(post.updated_on)
      entry.title post.title
      entry.summary post.description, :type => 'html'
      entry.content post.description,  :type => 'html'
      entry.author do |author|
        author.name  post.author
      end
    end
  end
end

