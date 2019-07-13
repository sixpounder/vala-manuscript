public class MessageInfoBar : Gtk.InfoBar {
  public string message { get; set; }

  public MessageInfoBar (string message, Gtk.MessageType type) {
    Object (
      show_close_button: true,
      message_type: type,
      message: message,
      revealed: true
    );
  }

  construct {
    Gtk.Label message_label = new Gtk.Label (this.message);
    this.get_content_area().add (message_label);
  }
}

