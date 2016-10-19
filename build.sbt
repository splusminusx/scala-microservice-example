import Settings._
import sbt._

name := "scala-deploy"

version := "1.0.1"

val additionalResolvers: Seq[MavenRepository] = Seq[MavenRepository](
  "Sonatype Livetex" at "http://sonatype-nexus.livetex.ru/nexus/content/groups/public",
  "Sonatype OSS" at "https://oss.sonatype.org/content/repositories/releases/",
  Resolver.sonatypeRepo("snapshots")
)

val commonSettings = Seq(
  resolvers ++= additionalResolvers,
  scalaVersion := "2.11.8"
)

lazy val root = (project in file("."))
  .enablePlugins(DockerPlugin, BuildInfoPlugin)
  .settings(commonSettings: _*)
  .settings(dockerSettings)
  .settings(buildInfoSettings)
  .settings(
    libraryDependencies ++= Seq(
      "com.typesafe"    % "config"                  % "1.3.0",
      "ch.qos.logback"  % "logback-classic"         % "1.1.3",
      "org.slf4j"       % "slf4j-api"               % "1.7.21",

      "ru.livetex"      %% "scala-utils-discovery"  % "0.1.14-SNAPSHOT"
    )
  )
