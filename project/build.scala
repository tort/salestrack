import sbt._
import Keys._
import AndroidKeys._

object SalesTrack extends Build {
  lazy val root = Project(
    id = "root",
    base = file("."),
    settings = buildSettings
  ) aggregate(model, android, replicator)

  lazy val model = Project(
    id = "model",
    base = file("model"),
    settings = buildSettings
  )

  lazy val android = Project(
    id = "android",
    base = file("android"),
    settings = buildSettings ++ AndroidSettings.full
  )

  lazy val replicator = Project(
    id = "dbreplicator",
    base = file("dbreplicator"),
    settings = buildSettings
  ) dependsOn (model)

  val buildSettings = Defaults.defaultSettings ++ Seq(
    scalaVersion := "2.10.0"
  )
}

object AndroidSettings {
  val settings = Defaults.defaultSettings ++ Seq(
    name := "android",
    version := "0.1",
    versionCode := 0,
    platformName in Android := "android-16"
  )

  val proguardSettings = Seq(
    proguardOption in Android := "-keep class scala.collection.SeqLike {public protected *;}"
  )

  lazy val full =
    AndroidSettings.settings ++
      AndroidProject.androidSettings ++
      TypedResources.settings ++
      proguardSettings ++
      AndroidManifestGenerator.settings ++
      AndroidMarketPublish.settings ++ Seq(
      keyalias in Android := "change-me",
      libraryDependencies += "org.scalatest" % "scalatest_2.10" % "1.9.1" % "test",
      libraryDependencies += "com.h2database" % "h2" % "1.3.168",
      libraryDependencies += "org.scalaz" % "scalaz-core_2.10" % "7.0.5",
      libraryDependencies += "com.typesafe" % "slick_2.10" % "1.0.0-RC2",
      libraryDependencies += "com.fasterxml.uuid" % "java-uuid-generator" % "3.1.3"
    )
}

