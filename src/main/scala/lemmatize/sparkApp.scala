package lemmatize
import org.apache.spark.sql.SparkSession
import com.atlascopco.hunspell.Hunspell
import scala.collection.mutable
import scala.collection.JavaConverters._
import org.apache.spark.sql.functions.{udf}

/*
*Création d'une class Words, avec comme type de champ,
* le meme type que celui que retourne la fonction lem du Hunspell objet
* Hunspell renvoie une liste de type util.List il nous suffira juste de faire une conversion.
* */
case class Words( words_lem: List[String])

object SimpleSparkApp extends App {
  // Création d'une SparkSession
  val spark = SparkSession
    .builder()
    .appName("lemmatizer")
    .master("local[*]")
    .getOrCreate()

  spark.sparkContext.setLogLevel("ERROR")

  import spark.implicits._
  // instancier l'Hunspell objet
  val lem = new Hunspell("\\hunspell_lem\\src\\main\\scala\\lemmatize\\hunspell\\dictionaries\\fr\\fr-moderne.dic", "\\hunspell_lem\\src\\main\\scala\\lemmatize\\hunspell\\dictionaries\\fr\\fr-moderne.aff")
  // Lecture du fichier CSV ( input ) dans un dataframe
  val df = spark.read.option("header",true).csv("\\hunspell_lem\\src\\main\\scala\\lemmatize\\words.csv")

  // Initialisation d'une liste mutable de type (Words) pour récupérer les résultats retourner par le Hunspell Objet
  val listeOfLem  = mutable.MutableList[Words]()

  // Parcourir le dataframe ( input ) et lemmatizer les mots qu'on a en entrée
  for (row <- df.rdd.collect)
    {
      val listLem = lem.stem(row.getString(0))
      // conversion util.List -> List
      val my_words = listLem.asScala.toList
      // Créer un objet Words et l'ajouter à notre liste de lem
      listeOfLem += new Words(my_words)
    }

  val maListe = listeOfLem.toList
  println(maListe.take(20))
  // Conversion List -> Dataframe
  val dfOutput = maListe.toDF()
  println(dfOutput.show())

  /*
  * La colonne "words_lem" de notre Dataframe est de type List[String].
  * L'écriture d'un DataFrame sous format CSV ne permet pas d'avoir des colonnes de ce type
  * La fonction adapter (spark udf) permet de gérer cette erreur, en "Unpack" la liste
  * */
  val adapter = udf((vs: Seq[String]) => vs match {
    case null => null
    case _    => s"""[${vs.mkString(",")}]"""
  })

  //dfOutput.withColumn("words_lem", adapter($"words_lem")).write.csv("myfile.csv")

}
