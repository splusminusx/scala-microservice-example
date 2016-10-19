package com.github.splusminusx.scaladeploy

import java.io.File

import com.twitter.finagle.Http
import com.twitter.util.Await
import org.slf4j.LoggerFactory
import com.typesafe.config.Config
import com.typesafe.config.ConfigFactory
import ru.livetex.discovery._
import scala.concurrent.duration._
import scala.collection.JavaConverters._

object Application extends App {

  val log = LoggerFactory.getLogger(getClass)

  val serviceName               = BuildInfo.name
  val version                   = BuildInfo.version
  val hostIpAddress             = getConfig.getString("host_ip")
  val port                      = getConfig.getInt("port")
  val profile                   = getConfig.getString("profile")
  val announceToCircuits        = getConfig.getStringList("circuits").asScala.toList
  val findDependenciesInCircuit = getConfig.getString("default_circuit")

  logInitialParams()

  val registrator     = Registrator(hostIpAddress, DEFAULT_PORT)
  val resolver        = ConsulHealthClient(hostIpAddress)
  val server          = Http.serve(s":$port", new HttpService)

  selfRegister()

  while(true) {
    Thread.sleep(1.seconds.toMillis)
    logConfig()
    logEndpoints()
  }

  Await.ready(server)

  private def getConfig: Config = {
    val files = Set(
      "/app/etc/application.conf",
      "./etc/application.conf"
    ).map(new File(_)).filter(_.exists())
    log.trace(s"Available configurations $files")

    // get reference config
    val default = ConfigFactory.defaultReference()

    // get config from custom location
    val custom = files.headOption match {
      case Some(file) => ConfigFactory.parseFile(file)
      case _ => ConfigFactory.empty()
    }

    // merge custom and reference config
    custom.withFallback(default).resolve()
  }

  private def selfRegister(): Unit = {
    try {
      Await.result(registrator.registerEndpoint(
        id        = s"$serviceName-$profile",
        name      = serviceName,
        circuits  = announceToCircuits,
        version   = Some(version),
        port      = port,
        address   = hostIpAddress,
        check     = HttpCheck(
          id    = s"$serviceName-$profile-http-check",
          name  = s"$serviceName-$profile-http-check",
          http  = s"http://$hostIpAddress:$port"
        )
      ))
      log.info("Registered in consul successful.")
    } catch {
      case e: Throwable =>
        log.error(s"Unable to register in Consul. ${e.getMessage}")
        System.exit(1)
    }
  }

  private def logConfig(): Unit = {
    log.debug(s"some_key=${getConfig.getString("some_key")}")
  }

  private def logEndpoints(): Unit = {
    val endpoints = Await.result(
      resolver.getEndpoints(
        name    = serviceName,
        circuit = Some(findDependenciesInCircuit),
        version = None
      )
    )
    log.debug(s"$endpoints")
  }

  private def logInitialParams(): Unit = {
    log.info(
      s"""service                   = $serviceName\n
          |profile                   = $profile\n
          |ipAddress                 = $hostIpAddress\n
          |port                      = $port\n
          |version                   = $version\n
          |announceToCircuits        = $announceToCircuits
          |findDependenciesInCircuit = $findDependenciesInCircuit
          |""".stripMargin)
  }

}
