# rm(list = ls())   
# options(editor = 'notepad')
library(tidyverse)
library('xlsx')


#       estrutura da NCM: xx.xx.xx.x.x  ----
#         cap�tulo ________|  |  | | |     SH_2    (V e XV; min�rios e metais)
#         posi��o_____________|  | | |     SH_4    
#         subposi��o_____________| | |     SH_6
#         item_____________________| |
#         subitem____________________|


#      estrutura da CNAE: B  x x.x x-x/x x  ----
#       se��o ____________|  | | | | | | |      B e C - IND�STRIAS EXTRATIVAS e IND�STRIAS DE TRANSFORMA��O
#       divis�o _____________|_| | | | | |
#       grupo ___________________| | | | |
#       classe ____________________|_| | |
#       subclasse _____________________|_|


# rm(list = ls())   
source('D:/Users/humberto.serna/Desktop/Anuario_Mineral_Brasileiro/Funcoes_de_Formatacao_Estilo/Funcoes_de_Formatacao_Estilo.R')


# carregamento ----
# _____ Tabela de Relacionamentos  ----

NCM_CNAE_Relacionamentos <-                                 # tabela do Mariano Laio
  read.table(
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/NCM_CNAE_Relacionamentos_FINAL.csv',
    header = TRUE,
    sep = ";",
    #skip = 1286, nrows = 1,
    stringsAsFactors = FALSE, colClasses = c('character'),
    quote = "\"",    #  'aspas simples na string
    encoding = "UTF-8"#, fill = TRUE
  )

colnames(NCM_CNAE_Relacionamentos) <-
  FUNA_removeAcentos(colnames(NCM_CNAE_Relacionamentos))

NCM_CNAE_Relacionamentos$SUBSTANCIA <- 
  NCM_CNAE_Relacionamentos$SUBSTANCIA %>% str_squish()

# __________ NCMs da Minera��o

NCM_Mineracao <- 
  unique(NCM_CNAE_Relacionamentos$CO_NCM)

# _____ unidades de medida -----
und_medida <-
  read.table(
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/NCM_UNIDADE.csv',
    header = TRUE,
    sep = ";", 
    colClasses = c('character'),
    stringsAsFactors = FALSE, 
    encoding = "UTF-8"#, fill = TRUE     #  UTF-8 cont�m US-ASCII 
  )





# _____ BASE EXPORTA�AO                            ####

# carregar arquivo pronto    

# exportacao <- readRDS(file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/EXP_COMPLETA.RDATA')

exportacao <- #  fazer uma vez, e salvar em RDATA
 read.table(
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/EXP_2020.csv',
    header =  TRUE,
    sep = ";", #skip =  19038449, 15800261, nrows = 5823354,
    stringsAsFactors = FALSE, 
    colClasses = c('character','character','character','character','character','character','character','character','numeric','numeric','numeric'),
     col.names = c("CO_ANO","CO_MES","CO_NCM","CO_UNID","CO_PAIS","SG_UF_NCM","CO_VIA","CO_URF","QT_ESTAT","KG_LIQUIDO","VL_FOB"),
     quote = "\"",  #    'aspas simples na string
    encoding = "UTF-8", fill = TRUE #       UTF-8 cont�m US-ASCII 
  )

#    saveRDS(object = exportacao, file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/EXP_COMPLETA.RDATA')


# __________ und de medida 
exportacao <- 
  left_join(exportacao, und_medida, by = "CO_UNID")

# __________ exportacao de produtos NCMs minera��o ----

exportacao <-
  exportacao[exportacao$CO_NCM %in% NCM_Mineracao,]

# __________ Jun��o com Tabela de Relacionamentos NCMs-CNAES-Subst�ncias ----

exportacao <-
  left_join(exportacao, unique(NCM_CNAE_Relacionamentos[, c("CO_NCM",
                                                            "NO_NCM_POR",
                                                            "CO_FAT_AGREG",
                                                            "NO_FAT_AGREG",
                                                            "SUBSTANCIA",
                                                            #"CNAE.2.3.Classe.Codigo...ProdList.2019",
                                                            #"CNAE.2.3.Classe.Descricao...ProdList.2019",
                                                            "CNAE.2.3.Secao.Codigo",
                                                            "CNAE.2.3.Secao.Descricao",
                                                            #"CNAE.2.3.Divisao.Codigo",
                                                            #"CNAE.2.3.Divisao.Descricao",
                                                            #"CNAE.2.3.Grupo.Codigo",
                                                            #"CNAE.2.3.Grupo.Descricao",
                                                            "PRODUTO.ProdList.Ind.2019.Codigo",
                                                            "PRODUTO.ProdList.Ind.2019.Descricao"#,
                                                            #"ProdList.Servicos.associados.2019.Codigo",
                                                            #"ProdList.Servicos.associados.2019.Descricao",
                                                            #"CNAE.2.3.Classe.Codigo...ProdList.2016",
                                                            #"CNAE.2.3.Classe.Descricao...ProdList.2016",
                                                            #PRODUTO.ProdList.Ind.2016.Codigo",
                                                            #PRODUTO.ProdList.Ind.2016.Descricao",
                                                            #"ProdList.Servicos.associados.2016.Codigo",
                                                            #"ProdList.Servicos.associados.2016.Descricao"
                                                            )]), 
            by = "CO_NCM")

# __________ Pa�s ----
pais <- 
  read.table(file = "./CSV_Data/Comex_Mineracao/PAIS.csv", header = TRUE, sep = ";", stringsAsFactors = FALSE, colClasses = 'character')

pais <- 
  pais[,c(
    "CO_PAIS", 
    #  "CO_PAIS_ISON3", 
    #  "CO_PAIS_ISOA3", 
    "NO_PAIS" #, 
    #  "NO_PAIS_ING", 
    #  "NO_PAIS_ESP"
  )]

exportacao <- 
  left_join(exportacao, pais, by = "CO_PAIS")


# __________ removendo aspas duplas em strings ----
exportacao$NO_NCM_POR <-
  gsub(pattern = "\"",
       replacement = "",
       x = exportacao$NO_NCM_POR)
exportacao$NO_FAT_AGREG <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$NO_FAT_AGREG
  )
exportacao$CNAE.2.3.Classe.Descricao...ProdList.2019 <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$CNAE.2.3.Classe.Descricao...ProdList.2019
  )
exportacao$CNAE.2.3.Secao.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$CNAE.2.3.Secao.Descricao
  )
exportacao$CNAE.2.3.Divisao.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$CNAE.2.3.Divisao.Descricao
  )
exportacao$CNAE.2.3.Grupo.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$CNAE.2.3.Grupo.Descricao
  )
exportacao$PRODUTO.ProdList.Ind.2019.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$PRODUTO.ProdList.Ind.2019.Descricao
  )
exportacao$ProdList.Servicos.associados.2019.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$ProdList.Servicos.associados.2019.Descricao
  )
exportacao$CNAE.2.3.Classe.Descricao...ProdList.2016 <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$CNAE.2.3.Classe.Descricao...ProdList.2016
  )
exportacao$PRODUTO.ProdList.Ind.2016.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$PRODUTO.ProdList.Ind.2016.Descricao
  )
exportacao$ProdList.Servicos.associados.2016.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = exportacao$ProdList.Servicos.associados.2016.Descricao
  )





# __________ ciclo grava��o ----
for (ano in 1997:2020) {
  a <-
    exportacao[exportacao$CO_ANO == ano, ]
  
  write.table(
    x = a,
    file = paste(
      'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/',
      'EXPORTA��O_',
      ano,
      ".csv",
      sep = ""
    ),
    sep = ";",
    quote = TRUE,
    dec = ",",
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}



# _____ BASE IMPORTA�AO                           ####

#rm(exportacao)

# carregar arquivo pronto
# importacao <- readRDS(file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/IMP_COMPLETA.RDATA')

importacao <-
  read.table(
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/IMP_2020.csv',
    header = TRUE,   
    sep = ";", # skip = 28737260,  23417130, nrows = 9091054,
    stringsAsFactors = FALSE, 
    colClasses = c('character','character','character','character','character','character','character','character','numeric','numeric','numeric'),
    col.names = c("CO_ANO","CO_MES","CO_NCM","CO_UNID","CO_PAIS","SG_UF_NCM","CO_VIA","CO_URF","QT_ESTAT","KG_LIQUIDO","VL_FOB"),
     quote = "\"",  #    'aspas simples na string
    encoding = "UTF-8", fill = TRUE #      UTF-8 cont�m US-ASCII 
  )

# saveRDS(object = importacao,  file = 'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/IMP_COMPLETA.RDATA')

# __________ und de medida 
importacao <- 
  left_join(importacao, und_medida, by = "CO_UNID")


# __________ importacao de produtos NCMs minera��o ----

importacao <-
  importacao[importacao$CO_NCM %in% NCM_Mineracao,]  

# __________ Jun��o com Tabela de Relacionamentos NCMs-CNAES-Subst�ncias ----
importacao <-
  left_join(importacao,
            unique(NCM_CNAE_Relacionamentos[, c("CO_NCM",
                                                "NO_NCM_POR",
                                                "CO_FAT_AGREG",
                                                "NO_FAT_AGREG",
                                                "SUBSTANCIA",
                                                #"CNAE.2.3.Classe.Codigo...ProdList.2019",
                                                #"CNAE.2.3.Classe.Descricao...ProdList.2019",
                                                "CNAE.2.3.Secao.Codigo",
                                                "CNAE.2.3.Secao.Descricao",
                                                "CNAE.2.3.Divisao.Codigo",
                                                "CNAE.2.3.Divisao.Descricao"#,
                                                #"CNAE.2.3.Grupo.Codigo",
                                                #"CNAE.2.3.Grupo.Descricao",
                                                #"PRODUTO.ProdList.Ind.2019.Codigo",
                                                #"PRODUTO.ProdList.Ind.2019.Descricao",
                                                #"ProdList.Servicos.associados.2019.Codigo",
                                                #"ProdList.Servicos.associados.2019.Descricao",
                                                #"CNAE.2.3.Classe.Codigo...ProdList.2016",
                                                #"CNAE.2.3.Classe.Descricao...ProdList.2016",
                                                #"PRODUTO.ProdList.Ind.2016.Codigo",
                                                #"PRODUTO.ProdList.Ind.2016.Descricao",
                                                #"ProdList.Servicos.associados.2016.Codigo",
                                                #"ProdList.Servicos.associados.2016.Descricao"
                                                )]),
            by = "CO_NCM")


# __________ Pa�s ----
importacao <- 
  left_join(importacao, pais, by = "CO_PAIS")



# __________ removendo aspas duplas em strings ----
importacao$NO_NCM_POR <-
  gsub(pattern = "\"",
       replacement = "",
       x = importacao$NO_NCM_POR)
importacao$NO_FAT_AGREG <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$NO_FAT_AGREG
  )
importacao$CNAE.2.3.Classe.Descricao...ProdList.2019 <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$CNAE.2.3.Classe.Descricao...ProdList.2019
  )
importacao$CNAE.2.3.Secao.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$CNAE.2.3.Secao.Descricao
  )
importacao$CNAE.2.3.Divisao.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$CNAE.2.3.Divisao.Descricao
  )
importacao$CNAE.2.3.Grupo.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$CNAE.2.3.Grupo.Descricao
  )
importacao$PRODUTO.ProdList.Ind.2019.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$PRODUTO.ProdList.Ind.2019.Descricao
  )
importacao$ProdList.Servicos.associados.2019.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$ProdList.Servicos.associados.2019.Descricao
  )
importacao$CNAE.2.3.Classe.Descricao...ProdList.2016 <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$CNAE.2.3.Classe.Descricao...ProdList.2016
  )
importacao$PRODUTO.ProdList.Ind.2016.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$PRODUTO.ProdList.Ind.2016.Descricao
  )
importacao$ProdList.Servicos.associados.2016.Descricao <-
  gsub(
    pattern = "\"",
    replacement = "",
    x = importacao$ProdList.Servicos.associados.2016.Descricao
  )



# __________ ciclo grava��o ----
for (ano in 1997:2020) {
  a <-
    importacao[importacao$CO_ANO == ano, ]
  
  write.table(
    x = a,
    file = paste(
      'D:/Users/humberto.serna/Documents/CSV_Data/Comex_Mineracao/',
      'IMPORTA��O_',
      ano,
      ".csv",
      sep = ""
    ),
    sep = ";",
    quote = TRUE,
    dec = ",",
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}




exportacao$tipo_de_opera��o <- c("exportacao")
importacao$tipo_de_opera��o <- c("importacao")


tabela_com�rcio_exterior <-
  bind_rows(exportacao[, c(
    "tipo_de_opera��o",
    "CO_ANO",
    "CO_MES",
    "SUBSTANCIA.x",
    "CO_NCM",
    "NO_NCM_POR",
    "CO_FAT_AGREG.x",
    "NO_FAT_AGREG.x",
    "QT_ESTAT",
    "NO_UNID.x",
    "SG_UNID.x",
    "KG_LIQUIDO",
    "VL_FOB",
    "SG_UF_NCM",
    "CO_PAIS",
    "NO_PAIS.x",
    "CO_VIA",
    "CO_URF",
    "CNAE.2.3.Classe.Codigo...ProdList.2019",
    "CNAE.2.3.Classe.Descricao...ProdList.2019",
    "CNAE.2.3.Secao.Codigo",
    "CNAE.2.3.Secao.Descricao",
    "CNAE.2.3.Divisao.Codigo",
    "CNAE.2.3.Divisao.Descricao",
    "CNAE.2.3.Grupo.Codigo",
    "CNAE.2.3.Grupo.Descricao",
    "PRODUTO.ProdList.Ind.2019.Codigo",
    "PRODUTO.ProdList.Ind.2019.Descricao",
    "ProdList.Servicos.associados.2019.Codigo",
    "ProdList.Servicos.associados.2019.Descricao",
    "CNAE.2.3.Classe.Codigo...ProdList.2016",
    "CNAE.2.3.Classe.Descricao...ProdList.2016",
    "PRODUTO.ProdList.Ind.2016.Codigo",
    "PRODUTO.ProdList.Ind.2016.Descricao",
    "ProdList.Servicos.associados.2016.Codigo",
    "ProdList.Servicos.associados.2016.Descricao"
  )],
  importacao[, c(
    "tipo_de_opera��o",
    "CO_ANO",
    "CO_MES",
    "SUBSTANCIA.x",
    "CO_NCM",
    "NO_NCM_POR",
    "CO_FAT_AGREG.x",
    "NO_FAT_AGREG.x",
    "QT_ESTAT",
    "NO_UNID.x",
    "SG_UNID.x",
    "KG_LIQUIDO",
    "VL_FOB",
    "SG_UF_NCM",
    "CO_PAIS",
    "NO_PAIS.x",
    "CO_VIA",
    "CO_URF",
    "CNAE.2.3.Classe.Codigo...ProdList.2019",
    "CNAE.2.3.Classe.Descricao...ProdList.2019",
    "CNAE.2.3.Secao.Codigo",
    "CNAE.2.3.Secao.Descricao",
    "CNAE.2.3.Divisao.Codigo",
    "CNAE.2.3.Divisao.Descricao",
    "CNAE.2.3.Grupo.Codigo",
    "CNAE.2.3.Grupo.Descricao",
    "PRODUTO.ProdList.Ind.2019.Codigo",
    "PRODUTO.ProdList.Ind.2019.Descricao",
    "ProdList.Servicos.associados.2019.Codigo",
    "ProdList.Servicos.associados.2019.Descricao",
    "CNAE.2.3.Classe.Codigo...ProdList.2016",
    "CNAE.2.3.Classe.Descricao...ProdList.2016",
    "PRODUTO.ProdList.Ind.2016.Codigo",
    "PRODUTO.ProdList.Ind.2016.Descricao",
    "ProdList.Servicos.associados.2016.Codigo",
    "ProdList.Servicos.associados.2016.Descricao"
  )])

# grava��o ----

tabela_com�rcio_exterior$NO_NCM_POR <- 
  gsub(pattern = "\"", replacement = "", x = tabela_com�rcio_exterior$NO_NCM_POR)

write.table(importacao, file = 'importa��o.csv', sep = ";", quote = TRUE, 
            dec = ",", row.names = FALSE, fileEncoding = "UTF-8")



