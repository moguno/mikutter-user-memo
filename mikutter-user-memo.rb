Plugin.create(:mikutter_user_memo) {
  require "yaml"

  DATA_FILE = File.join(CHIConfig::SETTINGDIR, "memo.yaml")


  on_boot { |service|
    load_memo
  }


  def load_memo
    @memo = if File.exist?(DATA_FILE)
      YAML.load_file(DATA_FILE)
    else
      {}
    end
  end

  def set_memo(screen_name, memo)
    load_memo
    @memo[screen_name] = memo
 
    File.open(DATA_FILE, "w") { |fp|
      fp.puts YAML.dump(@memo)
    }
  end

  def get_memo(screen_name)
    @memo[screen_name] || ""
  end


  profiletab(:memo, "メモ") {
    set_icon File.join(File.dirname(__FILE__), "Crystal_Clear_app_kedit.png")

    vbox = ::Gtk::VBox.new
    box = ::Gtk::HBox.new

    edit = ::Gtk::TextView.new
    edit.buffer.text = Plugin[:mikutter_user_memo].get_memo(user[:idname])

    button = ::Gtk::Button.new("登録")

    _user = user

    button.ssc(:clicked) {
      Plugin[:mikutter_user_memo].set_memo(user[:idname], edit.buffer.text)
    }
    
    box.pack_start(edit)
    box.pack_start(button, false)

    vbox.pack_start(box, false)

    nativewidget vbox
  }


  class SubPartsMemo < ::Gdk::SubParts
    regist

    def initialize(*args)
      super(*args)

      @memo = Plugin[:mikutter_user_memo].get_memo(helper.message[:user][:idname])
    end

    def get_memo_layout(context = dummy_context)
      (attr_list, text) = Pango.parse_markup(@memo)
      layout = context.create_pango_layout
      layout.width = width * Pango::SCALE
      layout.attributes = attr_list
      layout.wrap = Pango::WRAP_CHAR
      layout.font_description = Pango::FontDescription.new(UserConfig[:memo_font])
      layout.text = @memo

      layout
    end

    def height
      if UserConfig[:memo_show_tl] && (@memo != "") && (!helper.destroyed?)
        get_memo_layout.pixel_size[1]
      else
        0
      end
    end

    def render(context)
      if UserConfig[:memo_show_tl] && (@memo != "") && helper.visible? && helper.message
        context.save{
          icon_size = 16

          context.translate(helper.icon_margin, 0)
          pixbuf = Gdk::Pixbuf.new(File.join(File.dirname(__FILE__), "Crystal_Clear_app_kedit.png"), icon_size, icon_size)
          context.set_source_pixbuf(pixbuf)
          context.paint

          context.translate(icon_size + helper.icon_margin * 2, 0)
          context.set_source_rgb(*(UserConfig[:memo_font_color] || [0,0,0]).map{ |c| c.to_f / 65536 })
          context.show_pango_layout(get_memo_layout(context))
        }
      end
    end
  end


  UserConfig[:memo_show_tl] ||= true
  UserConfig[:memo_font] ||= UserConfig[:mumble_reply_font]
  UserConfig[:memo_font_color] ||= [3145, 858, 50507]

  settings("メモ") {
    boolean("TLにメモを表示する", :memo_show_tl)
    fontcolor("フォント", :memo_font, :memo_font_color)
  }
} 
