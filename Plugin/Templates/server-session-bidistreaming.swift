// {{ method.name }} (Bidirectional Streaming)
public class {{ .|session:file,service,method }} : {{ .|service:file,service }}Session {
  private var provider : {{ .|provider:file,service }}

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: {{ .|provider:file,service }}) {
    self.provider = provider
    super.init(handler:handler)
  }

  /// Receive a message. Blocks until a message is received or the client closes the connection.
  public func receive() throws -> {{ method|input }} {
    let sem = DispatchSemaphore(value: 0)
    var requestMessage : {{ method|input }}?
    try self.handler.receiveMessage() {(requestData) in
      if let requestData = requestData {
        do {
          requestMessage = try {{ method|input }}(serializedData:requestData)
        } catch (let error) {
          print("error \(error)")
        }
      }
      sem.signal()
    }
    _ = sem.wait(timeout: DispatchTime.distantFuture)
    if let requestMessage = requestMessage {
      return requestMessage
    } else {
      throw {{ .|servererror:file,service }}.endOfStream
    }
  }

  /// Send a message. Nonblocking.
  public func send(_ response: {{ method|output }}) throws {
    try handler.sendResponse(message:response.serializedData()) {}
  }

  /// Close a connection. Blocks until the connection is closed.
  public func close() throws {
    let sem = DispatchSemaphore(value: 0)
    try self.handler.sendStatus(statusCode:self.statusCode,
                                statusMessage:self.statusMessage,
                                trailingMetadata:self.trailingMetadata) {
                                  sem.signal()
    }
    _ = sem.wait(timeout: DispatchTime.distantFuture)
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) throws {
    try self.handler.sendMetadata(initialMetadata:initialMetadata) {
      queue.async {
        do {
          try self.provider.{{ method.name|lowercase }}(session:self)
        } catch (let error) {
          print("error \(error)")
        }
      }
    }
  }
}
