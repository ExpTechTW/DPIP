// Replays the touch script tool/dev/bench_map.sh generates, on the device.
//
// Runs under app_process as root, once per gesture window: one process for
// the whole script, so the frames arrive 16 ms apart as written. A shell loop
// of `cat` and `sleep` spends tens of milliseconds starting each of them and
// turned a 17 s script into a 59 s slow motion one.
//
// Plan format, repeated to the end of the file (big-endian headers):
//   int32 microseconds to wait after this chunk
//   int32 chunk length
//   bytes raw `struct input_event` records for the touchscreen
import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.EOFException;
import java.io.FileInputStream;
import java.io.FileOutputStream;

public final class Inject {
  public static void main(String[] args) throws Exception {
    DataInputStream in =
        new DataInputStream(new BufferedInputStream(new FileInputStream(args[0])));
    FileOutputStream out = new FileOutputStream(args[1]);
    long next = System.nanoTime();
    while (true) {
      int waitMicros;
      try {
        waitMicros = in.readInt();
      } catch (EOFException end) {
        break;
      }
      byte[] chunk = new byte[in.readInt()];
      in.readFully(chunk);
      out.write(chunk);
      // Against a fixed schedule, not a sleep per chunk: late writes catch up
      // instead of stretching the gesture.
      next += waitMicros * 1000L;
      long delay = next - System.nanoTime();
      if (delay > 0) Thread.sleep(delay / 1_000_000, (int) (delay % 1_000_000));
    }
    out.close();
  }
}
