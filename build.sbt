name := "hunspell_lem"

version := "0.1"

scalaVersion := "2.12.12"

libraryDependencies += "org.apache.spark" %% "spark-core" % "3.0.1"
libraryDependencies += "com.atlascopco" % "hunspell-bridj" % "1.0.4"
libraryDependencies += "org.apache.spark" %% "spark-sql" % "3.0.1"
