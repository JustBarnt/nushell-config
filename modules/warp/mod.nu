def locations [] {
  {
    options: { case_sensitive: false, completion_algorithm: prefix, positional: true, sort: true },
    completions: ["asinc", "ccic", "ccicdb", "clips", "clipsdb", "xmlapi",] 
  }
}

export def --env main [prefix: string@locations] {
  match $prefix {
    "asinc" => {
      cd D:/CommSys/ASINC/Asinc/
    },
    "ccic" => {
      cd D:/CommSys/ConnectCIC/ConnectCIC/
    },
    "ccicdb" => {
      cd D:/CommSys/ConnectCIC/database/
    },
    "clips" => {
      cd D:/CommSys/CLIPS/CLIPS/Application/
    },
    "clipsdb" => {
      cd D:/CommSys/CLIPS/Database-1/
    },
    "xmlapi" => {
      cd D:/CommSys/ConnectCIC/XmlApi/
    },
  }
}

