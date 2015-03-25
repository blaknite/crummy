# encoding: utf-8

module Crummy
  class StandardRenderer
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper unless self.included_modules.include?(ActionView::Helpers::TagHelper)
    ActionView::Helpers::TagHelper::BOOLEAN_ATTRIBUTES.merge([:itemscope].to_set)
    include ERB::Util

    # Render the list of crumbs as either html or xml
    #
    # Takes 3 options:
    # The output format. Can either be xml or html. Default :html
    #   :format => (:html|:xml)
    # The separator text. It does not assume you want spaces on either side so you must specify. Default +&raquo;+ for :html and +crumb+ for xml
    #   :separator => string
    # Render links in the output. Default +true+
    #   :link => boolean
    #
    #   Examples:
    #   render_crumbs                         #=> <a href="/">Home</a> &raquo; <a href="/businesses">Businesses</a>
    #   render_crumbs :separator => ' | '     #=> <a href="/">Home</a> | <a href="/businesses">Businesses</a>
    #   render_crumbs :format => :xml         #=> <crumb href="/">Home</crumb><crumb href="/businesses">Businesses</crumb>
    #   render_crumbs :format => :html_list   #=> <ul class="" id=""><li class=""><a href="/">Home</a></li><li class=""><a href="/">Businesses</a></li></ul>
    #
    # With :format => :html_list you can specify additional params: li_class, ul_class, ul_id
    # The only argument is for the separator text. It does not assume you want spaces on either side so you must specify. Defaults to +&raquo;+
    #
    #   render_crumbs(" . ")  #=> <a href="/">Home</a> . <a href="/businesses">Businesses</a>
    #
    def render_crumbs(crumbs, options = {})

      options[:skip_if_blank] ||= Crummy.configuration.skip_if_blank
      return '' if options[:skip_if_blank] && crumbs.count < 1

      options[:format] ||= Crummy.configuration.format
      options[:right_to_left] ||= Crummy.configuration.right_to_left
      options[:separator] ||= Crummy.configuration.send(:"#{options[:format]}_#{'right_to_left_' if options[:right_to_left]}separator")
      options[:render_with_links] ||= Crummy.configuration.render_with_links
      options[:container_class] ||= Crummy.configuration.container_class
      options[:default_crumb_class] ||= Crummy.configuration.default_crumb_class
      options[:first_crumb_class] ||= Crummy.configuration.first_crumb_class
      options[:last_crumb_class] ||= Crummy.configuration.last_crumb_class
      options[:link_last_crumb] ||= Crummy.configuration.link_last_crumb
      options[:container_html] ||= {}

      options[:crumb_options] = {}
      options[:crumb_options][:truncate] = options.delete(:truncate) || Crummy.configuration.truncate
      options[:crumb_options][:escape] = options.delete(:escape) || Crummy.configuration.escape
      options[:crumb_options][:html] = options.delete(:crumb_html) || Crummy.configuration.crumb_html

      crumbs = crumbs.reverse if options[:right_to_left]

      case options[:format]
      when :html
        crumbs.each_with_index.map{ |crumb, index|
          crumb_to_html(crumb, index, crumbs.count, options)
        }.compact.join(options[:separator]).html_safe
      when :html_list
        inner_html = crumbs.each_with_index.map{ |crumb, index|
          crumb_to_html_list(crumb, index, crumbs.count, options)
        }.compact.join(options[:separator]).html_safe
        content_tag(:ul, inner_html, options[:container_html])
      when :xml
        crumbs.each_with_index.map{ |crumb, index|
          crumb_to_xml(crumb, index, crumbs.count, options)
        }.compact.join(options[:separator]).html_safe
      else
        raise ArgumentError, "Unknown breadcrumb output format"
      end
    end

    private

    def crumb_to_html(crumb, index, total, options)
      name, url, crumb_options = normalize_crumb(crumb, index, total, options)

      if url && options[:render_with_links] && ( index != total || options[:last_crumb_linked] )
        link_to(name, url, crumb_options[:html])
      else
        content_tag(:span, name, crumb_options[:html])
      end
    end

    def crumb_to_html_list(crumb, index, total, options)
      name, url, crumb_options = normalize_crumb(crumb, index, total, options)

      if url && options[:render_with_links] && ( index != total || options[:last_crumb_linked] )
        content_tag(:li, link_to(name, url), crumb_options[:html])
      else
        content_tag(:li, content_tag(:span, name), crumb_options[:html])
      end
    end

    def crumb_to_xml(crumb, index, total, options)
      name, url, options = normalize_crumb(crumb, index, total, options)

      content_tag(separator, name, href: (url && options[:render_with_links] ? url : nil))
    end

    def normalize_crumb(crumb, index, total, options)
      name, url, crumb_options = crumb
      crumb_options = {} unless crumb_options.is_a?(Hash)

      crumb_options = options[:crumb_options].merge(crumb_options)

      name = name.truncate(crumb_options[:truncate]) if crumb_options[:truncate].present?
      name = h(name) if crumb_options[:escape]

      html_classes = []
      html_classes << options[:default_crumb_class] if options[:default_crumb_class].present?
      html_classes << options[:first_crumb_class] if options[:first_crumb_class].present? && index == 0
      html_classes << options[:last_crumb_class] if options[:last_crumb_class].present? && index == total

      unless html_classes.empty?
        if crumb_options[:html][:class]
          crumb_options[:html][:class] = [crumb_options[:html][:class], html_classes].flatten.join(' ')
        else
          crumb_options[:html][:class] = html_classes.join(' ')
        end
      end

      [name, url, crumb_options]
    end
  end
end
