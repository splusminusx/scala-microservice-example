package com.github.splusminusx.scaladeploy

import com.twitter.finagle.Service
import com.twitter.finagle.http
import com.twitter.util.Future

/**
  * Test HTTP service.
  */
class HttpService extends Service[http.Request, http.Response] {
  override def apply(req: http.Request): Future[http.Response] = {
    Future.value(
      http.Response(req.version, http.Status.Ok)
    )
  }
}