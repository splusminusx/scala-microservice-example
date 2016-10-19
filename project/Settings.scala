import sbt.Keys._
import sbt._
import sbtbuildinfo.BuildInfoPlugin.autoImport._
import sbtdocker.DockerPlugin.autoImport._
import sbtdocker.ImageName

object Settings {
  val dockerSettings = Seq(
    docker <<= docker.dependsOn(Keys.`package`.in(Compile, packageBin)),
    imageNames in docker := Seq(
      ImageName(s"dh.livetex.ru/service/${name.value.toLowerCase}:latest"),
      ImageName(
        registry = Some("dh.livetex.ru"),
        repository = name.value.toLowerCase,
        namespace = Some("service"),
        tag = Some(version.value)
      )
    ),
    dockerfile in docker := {
      val jarFile = artifactPath.in(Compile, packageBin).value
      val classpath = managedClasspath.in(Compile).value
      val depClasspath = dependencyClasspath.in(Runtime).value
      val mainclass = mainClass.in(Compile, packageBin).value.get
      val app = "/app"
      val etc = s"$app/etc"
      val data = s"$app/data"
      val log = s"$app/log"
      val libs = s"$app/libs"
      val jarTarget = s"$app/${name.value}.jar"
      val classpathString = s"$libs/*:$jarTarget"
      new Dockerfile {
        from("dh.livetex.ru/lang/java:1.8")
        run("mkdir", app, etc, data, log)
        workDir(app)
        classpath.files.foreach { depFile =>
          val target = file(libs) / depFile.name
          stageFile(depFile, target)
        }
        depClasspath.files.foreach { depFile =>
          val target = file(libs) / depFile.name
          stageFile(depFile, target)
        }
        addRaw(libs, libs)
        add(jarFile, jarTarget)
        cmd("java", "-cp", classpathString, mainclass)
      }
    }
  )

  val buildInfoSettings = Seq(
    buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion),
    buildInfoPackage := "com.github.splusminusx.scaladeploy"
  )
}