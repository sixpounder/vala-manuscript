public class Stack<T> : Object {
  private Array<T> data = new Array<T>();
  private uint index { get; set; }
  public bool destructive { get; construct; }

  public signal void drain ();
  public Stack (bool destructive = true) {
    Object(
      destructive: destructive
    );

    this.index = -1;
  }

  public void push (T item) {
    this.data.append_val(item);
    this.index++;
  }

  public T pop () {
    if (this.data.length == 0) {
      this.drain();
      return null;
    } else {
      T item = this.destructive
        ? this.data.remove_index(this.index)
        : this.data.index(this.index);

      this.index--;

      return item;
    }
  }
}