require 'rubygems'
require 'bundler'
Bundler.require(:test)
require 'test/unit'

require 'action_controller'
require 'active_support/core_ext/string/output_safety'
require 'action_dispatch/testing/assertions'
require 'crummy'
require 'crummy/standard_renderer'

class StandardRendererTest < Test::Unit::TestCase
  include ActionDispatch::Assertions::DomAssertions
  include Crummy

  def test_classes
    renderer = StandardRenderer.new
    assert_equal('<a href="url" class="default first last">name</a>',
                 renderer.render_crumbs([['name', 'url']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :format => :html))
    assert_equal('<ul class=""><li class="default first last"><a href="url">name</a></li></ul>',
                 renderer.render_crumbs([['name', 'url']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :format => :html_list))
    assert_equal('<crumb href="url">name</crumb>',
                 renderer.render_crumbs([['name', 'url']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :format => :xml))

    assert_equal('<a href="url1" class="default first">name1</a> &raquo; <a href="url2" class="default">name2</a> &raquo; <a href="url3" class="default last">name3</a>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2'], ['name3', 'url3']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :format => :html))
    assert_equal('<ul class="container"><li class="default first"><a href="url1">name1</a></li><li class="default"><a href="url2">name2</a></li><li class="default last"><a href="url3">name3</a></li></ul>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2'], ['name3', 'url3']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :container_class => 'container', :format => :html_list))
    assert_equal('<ul class="container"><li class="default first"><a href="url1">name1</a></li> / <li class="default"><a href="url2">name2</a></li> / <li class="default last"><a href="url3">name3</a></li></ul>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2'], ['name3', 'url3']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :container_class => 'container', :format => :html_list, :separator => ' / '))
    assert_equal('<crumb href="url1">name1</crumb><crumb href="url2">name2</crumb>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2']], :default_crumb_class => 'default', :first_crumb_class => 'first', :last_crumb_class => 'last', :format => :xml))
  end

  def test_classes_last_crumb_not_linked
    renderer = StandardRenderer.new
    assert_equal('<span>name</span>',
                 renderer.render_crumbs([['name', 'url']], :format => :html, :link_last_crumb => false))
    assert_equal('<ul><li><span>name</span></li></ul>',
                 renderer.render_crumbs([['name', 'url']], :format => :html_list, :link_last_crumb => false))
    assert_equal('<crumb>name</crumb>',
                 renderer.render_crumbs([['name', 'url']], :format => :xml, :link_last_crumb => false))

    assert_equal('<a href="url1">name1</a> &raquo; <span>name2</span>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2']], :format => :html, :link_last_crumb => false))
    assert_equal('<ul><li><a href="url1">name1</a></li><li><a href="url2">name2</a></li><li><span>name3</span></li></ul>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2'], ['name3', 'url3']], :format => :html_list, :link_last_crumb => false))
    assert_equal('<ul><li><a href="url1">name1</a></li><li> / </li><li><a href="url2">name2</a></li><li> / </li><li><span>name3</span></li></ul>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2'], ['name3', 'url3']], :format => :html_list, :separator => ' / ', :link_last_crumb => false))
    assert_equal('<crumb href="url1">name1</crumb><crumb>name2</crumb>',
                 renderer.render_crumbs([['name1', 'url1'], ['name2', 'url2']], :format => :xml, :link_last_crumb => false))
  end

  def test_input_object_mutation
    renderer = StandardRenderer.new

    name1 = 'name1'
    url1 = nil
    name2 = 'name2'
    url2 = nil

    renderer.render_crumbs([[name1, url1], [name2, url2]], :format => :html, :microdata => false)

    # Rendering the crumbs shouldn't alter the input objects.
    assert_equal('name1', name1);
    assert_equal(nil, url2);
    assert_equal('name2', name2);
    assert_equal(nil, url2);
  end

  def test_html_options
    renderer = StandardRenderer.new

    assert_equal('<a href="url" title="title">name</a>',
                 renderer.render_crumbs([['name', 'url', :html => { :title => 'title' }]], :format => :html))

    assert_equal('<span title="title">name</span>',
                 renderer.render_crumbs([['name', 'url', :html => { :title => 'title' }]], :format => :html, :link_last_crumb => false))

    assert_equal('<ul><li title="title"><a href="url">name</a></li></ul>',
                 renderer.render_crumbs([['name', 'url', :html => { :title => 'title' }]], :format => :html_list))

    assert_equal('<ul><li title="title"><span>name</span></li></ul>',
                 renderer.render_crumbs([['name', 'url', :html_options => {:title => 'link title'}}]], :format => :html_list, :link_last_crumb => false))
  end

  def test_inline_configuration
    renderer = StandardRenderer.new
    Crummy.configure do |config|
      config.link_last_crumb = true
    end

    assert_no_match(/href/, renderer.render_crumbs([['name', 'url']], :link_last_crumb => false))
    assert_match(/href/, renderer.render_crumbs([['name', 'url']], :link_last_crumb => true))

    Crummy.configure do |config|
      config.link_last_crumb = false
    end

    assert_no_match(/href/, renderer.render_crumbs([['name', 'url']], :link_last_crumb => false))
    assert_match(/href/, renderer.render_crumbs([['name', 'url']], :link_last_crumb => true))
  end

  def test_configuration
    renderer = StandardRenderer.new
    # check defaults
    assert_equal " &raquo; ", Crummy.configuration.html_separator
    # adjust configuration
    Crummy.configure do |config|
      config.html_separator = " / "
    end
    assert_equal " / ", Crummy.configuration.html_separator
  end
end
