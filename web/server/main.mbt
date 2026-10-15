///|
async fn serve_file(
  conn : @http.ServerConnection,
  path : String,
  content_type : String,
) -> Unit {
  let file = @fs.open(path, mode=ReadOnly) catch {
    _ => {
      conn
      ..send_response(500, "InternalServerError")
      ..write("File not found; build the WASM package first")
      .end_response()
      return
    }
  }
  defer file.close()
  conn
  ..send_response(200, "OK", extra_headers={ "Content-Type": content_type })
  ..write_reader(file)
  .end_response()
}

///|
async fn main {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:8000"))
  println("Open http://127.0.0.1:8000/")
  server.run_forever((request, _body, conn) => {
    match (request.meth, request.path) {
      (Get, "/") =>
        serve_file(conn, "docs/index.html", "text/html; charset=utf-8")
      (Get, "/app.wasm") =>
        serve_file(conn, "docs/app.wasm", "application/wasm")
      _ =>
        conn..send_response(404, "NotFound")..write("Not found").end_response()
    }
  })
}
