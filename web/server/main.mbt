///|
async fn main {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:8000"))
  println("Open http://127.0.0.1:8000/")
  server.run_forever((request, _body, conn) => {
    if request.meth is Get && request.path == "/" {
      let file = @fs.open("web/index.html", mode=ReadOnly) catch {
        _ => {
          conn
          ..send_response(500, "InternalServerError")
          ..write("web/index.html was not found")
          .end_response()
          return
        }
      }
      defer file.close()
      conn
      ..send_response(200, "OK", extra_headers={
        "Content-Type": "text/html; charset=utf-8",
      })
      ..write_reader(file)
      .end_response()
    } else {
      conn..send_response(404, "NotFound")..write("Not found").end_response()
    }
  })
}
