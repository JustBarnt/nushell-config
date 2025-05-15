def locations [] {
  {
    options: { case_sensitive: false, completion_algorithm: prefix, positional: true, sort: true },
    completions: ["asinc", "case", "ccic", "ccicdb", "clips", "clipsdb", "docs", "jira", "proj", "xmlapi"] 
  }
}

export def --env main [prefix: string@locations] {
  match $prefix {
    "asinc" => { cd D:/CommSys/ASINC/Asinc/ },
    "ccic" => { cd D:/CommSys/ConnectCIC/ConnectCIC/ },
    "ccicdb" => { cd D:/CommSys/ConnectCIC/database/ },
    "clips" => { cd D:/CommSys/CLIPS/CLIPS/Application/ },
    "clipsdb" => { cd D:/CommSys/CLIPS/Database-1/ },
    "docs" => { cd D:/CommSys/ConnectCIC_SVN/ConnectCicDevDocs/ },
    "jira" => { cd D:/CommSys/Projects/JIRA/ },
    "proj" => { cd D:/CommSys/Projects/JIRA/PROJ/ },
    "xmlapi" => { cd D:/CommSys/ConnectCIC/XmlApi/ },
  }
}

