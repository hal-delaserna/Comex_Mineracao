# rm(list = ls())   
# options(editor = 'notepad')
library(tidyverse)
library('xlsx')

# rm(list = ls())   
source('D:/Users/humberto.serna/Desktop/Anuario_Mineral_Brasileiro/Funcoes_de_Formatacao_Estilo/Funcoes_de_Formatacao_Estilo.R')


#       estrutura da NCM: xx.xx.xx.x.x  ----
#         cap�tulo ________|  |  | | |     SH_2    (V e XV; min�rios e metais)
#         posi��o_____________|  | | |     SH_4    
#         subposi��o_____________| | |     SH_6
#         item_____________________| |
#         subitem____________________|


#      estrutura da CNAE: A  x x.x x-x/x x  ----
#       se��o ____________|  | | | | | | |      B e C - IND�STRIAS EXTRATIVAS e IND�STRIAS DE TRANSFORMA��O
#       divis�o _____________|_| | | | | |
#       grupo ___________________| | | | |
#       classe ____________________|_| | |
#       subclasse _____________________|_|


# carregamento ----
# _____ Tabela de Relacionamentos  ----

NCM_CNAE_Relacionamentos <-           # tabela do Mariano Laio
  read.table(
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/ComexStat/NCM_CNAE_Relacionamentos.csv',
    header = TRUE,
    sep = ";",
    #skip = 1286, nrows = 1,
    stringsAsFactors = FALSE, colClasses = c('character'),
    quote = "\"",    #  'aspas simples na string
    encoding = "ISO-8859"#, fill = TRUE
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
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/ComexStat/NCM_UNIDADE.csv',
    header = TRUE,
    sep = ";", 
    colClasses = c('character'),
    stringsAsFactors = FALSE, 
    encoding = "UTF-8"#, fill = TRUE     #  UTF-8 cont�m US-ASCII 
  )


# _____ BASE EXPORTA�AO                            ####
  
  # carregar arquivo pronto
exportacao <- readRDS(file = 'D:/Users/humberto.serna/Documents/CSV_Data/ComexStat/EXP_COMPLETA.RDATA')

# exportacao <-
#  read.table(
#    file = 'D:/Users/humberto.serna/Documents/CSV_Data/ComexStat/EXP_2020.csv',
#    header =  TRUE,
#    sep = ";", # skip =  19038449, 15800261, nrows = 5823354,
#    stringsAsFactors = FALSE, 
#    colClasses = c('character','character','character','character','character','character','character','character','numeric','numeric','numeric'),
#    col.names = c("CO_ANO","CO_MES","CO_NCM","CO_UNID","CO_PAIS","SG_UF_NCM","CO_VIA","CO_URF","QT_ESTAT","KG_LIQUIDO","VL_FOB"),
#     quote = "\"",    #  'aspas simples na string
#    encoding = "UTF-8", fill = TRUE     #  UTF-8 cont�m US-ASCII 
#  )

    

# __________ und de medida 
exportacao <- 
  left_join(exportacao, und_medida, by = "CO_UNID")

# __________ exportacao de produtos NCMs minera��o ----

exportacao <-
  exportacao[exportacao$CO_NCM %in% NCM_Mineracao,]


exportacao <- 
  left_join(exportacao, unique(NCM_CNAE_Relacionamentos[, c("CO_NCM", "CO_FAT_AGREG", "NO_FAT_AGREG", "SUBSTANCIA")]), by = "CO_NCM")

# __________ Pa�s ----
pais <- 
  read.table(file = "./CSV_Data/ComexStat/PAIS.csv", header = TRUE, sep = ";", stringsAsFactors = FALSE, colClasses = 'character')

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

# __________ Quantidades em Toneladas ----

exportacao$QUANTIDADE_TON <- 
  exportacao$KG_LIQUIDO / 1000

# __________ vetor de pre�os ----

exportacao$`VALOR_(usd/un)` <- 
  round(
    exportacao$VL_FOB /
      (exportacao$QT_ESTAT), 4) 

# ____________________ tratando valores infinitos 
exportacao[is.infinite(exportacao$`VALOR_(usd/un)`),]$`VALOR_(usd/un)` <- NaN



# __________ impondo grandezas em toneladas �s Subst�ncias do Sum�rio ----
listagem <- c("Alum�nio", "Areia", "Brita", "Calc�rio", "Carv�o", "Caulim", "Chumbo", #"�gua Mineral",
              "Cobalto", "Cobre", "Cromo", "Estanho", "Ferro", "Fosfato", "Grafita", "L�tio", "Magnesita",
              "Mangan�s", "Ni�bio", "N�quel", "Pot�ssio", "Prata", "Rochas Ornamentais", "T�ntalo", #"Ouro",
              "Terras Raras", "Tit�nio", "Tungst�nio", "Van�dio", "Zinco", "Zirc�nio")

exportacao[exportacao$SUBSTANCIA %in% listagem &
             exportacao$SG_UNID == "KGL" & is.na(exportacao$`VALOR_(usd/un)`) == FALSE,]$`VALOR_(usd/un)` <-
  exportacao[exportacao$SUBSTANCIA %in% listagem &
               exportacao$SG_UNID == "KGL" & is.na(exportacao$`VALOR_(usd/un)`) == FALSE,]$`VALOR_(usd/un)` * 1000

exportacao[exportacao$SUBSTANCIA %in% listagem &
             exportacao$SG_UNID == "KGL" & is.na(exportacao$QT_ESTAT) == FALSE,]$QT_ESTAT <-
  exportacao[exportacao$SUBSTANCIA %in% listagem &
               exportacao$SG_UNID == "KGL" & is.na(exportacao$QT_ESTAT) == FALSE,]$QT_ESTAT /1000

exportacao[exportacao$SUBSTANCIA %in% listagem &
             exportacao$SG_UNID == "KGL", ]$SG_UNID <- "TML"

exportacao[exportacao$SUBSTANCIA %in% listagem &
             exportacao$NO_UNID == "QUILOGRAMA LIQUIDO", ]$NO_UNID <-
  "TONELADA METRICA LIQUIDA"


# 1.a	Valor total das exporta��es do ano de refer�ncia e do ano anterior ----


df_1a <-
  select(exportacao, everything()) %>% #tibble()
  group_by(SUBSTANCIA, CO_ANO) %>% summarise(EX_FOB = sum(VL_FOB), QUANTIDADE_TON = sum(QUANTIDADE_TON))  # %>% tibble()



# 1.b	Distribui��o % do total de exporta��es quanto � forma: b�sico, manufaturado, etc. ----
                               
df_1b <- 
  select(exportacao, everything()) %>% #tibble()
  group_by(SUBSTANCIA, NO_FAT_AGREG, CO_ANO) %>% summarise(EX_FOB = sum(VL_FOB), QUANTIDADE_TON = sum(QUANTIDADE_TON))

      # impondo chave prim�ria p/ jun��o
      df_1b$id_Subs_Ano <- 
        paste(df_1b$SUBSTANCIA, df_1b$CO_ANO, sep = "_")
      
      df_1a$id_Subs_Ano <- 
        paste(df_1a$SUBSTANCIA, df_1a$CO_ANO, sep = "_")

df_1b <- 
  left_join(df_1b, df_1a[,c("id_Subs_Ano", "EX_FOB")], by = "id_Subs_Ano" )

df_1b$percentual_FAT_AGREG <- 
  round((df_1b$EX_FOB.x / df_1b$EX_FOB.y)*100, digits = 2)


df_1b <-
  df_1b[, c("CO_ANO",
            "SUBSTANCIA",
            "NO_FAT_AGREG",
            "EX_FOB.x",
            "QUANTIDADE_TON",
            "percentual_FAT_AGREG")]


# 1.c	Distribui��o % do total de exporta��es quanto aos pa�ses de destino ----

df_1c <-
  select(exportacao, everything()) %>% # tibble()
  group_by(SUBSTANCIA, CO_ANO, NO_PAIS) %>% summarise(EX_FOB = sum(VL_FOB), QUANTIDADE_TON = sum(QUANTIDADE_TON)) # %>% tibble()

            # impondo chave prim�ria p/ jun��o
           df_1c$id_Subs_Ano <- 
              paste(df_1c$SUBSTANCIA, df_1c$CO_ANO, sep = "_")

df_1c <- 
   left_join(df_1c, df_1a[,c("id_Subs_Ano", "EX_FOB")], by = "id_Subs_Ano" )
 
df_1c$percentual_PAIS <- 
   round((df_1c$EX_FOB.x / df_1c$EX_FOB.y)*100, digits = 3)
 
 
 df_1c <-
   df_1c[, c("CO_ANO",
             "SUBSTANCIA",
             "NO_PAIS",
             "EX_FOB.x",
             "QUANTIDADE_TON",
             "percentual_PAIS")]


# 1.d	Nome e NCM dos 3 principais produtos exportados e seus percentuais em rela��o ao valor total de exporta��es ----

df_1d <-
 select(exportacao, everything()) %>% # tibble()
 group_by(SUBSTANCIA, CO_ANO, CO_NCM) %>% summarise(EX_FOB = sum(VL_FOB), QUANTIDADE = sum(QT_ESTAT)) # %>% tibble()
 
 
# impondo chave prim�ria p/ jun��o com exporta��es totais por subst�ncia
df_1d$id_Subs_Ano <- 
  paste(df_1d$SUBSTANCIA, df_1d$CO_ANO, sep = "_")

df_1d <- 
  left_join(df_1d, df_1a[,c("id_Subs_Ano", "EX_FOB")], by = "id_Subs_Ano" )

df_1d$percentual_Produto_NCM <- 
  round((df_1d$EX_FOB.x / df_1d$EX_FOB.y)*100, digits = 3)


# extra��o 3 principais produtos exportados 
lista <- list()
i <- 1
for (ano in 2020) {
  for (substancia in sort(unique(NCM_CNAE_Relacionamentos$SUBSTANCIA))) {
    lista[[i]] <-
      head(arrange(df_1d[df_1d$CO_ANO == ano &
                           df_1d$SUBSTANCIA == substancia,], desc(percentual_Produto_NCM)), 10)
    i <- i + 1
  }
}

df_1d <-
  do.call(what = "rbind", args = lista)

# _____ Colunas de Unidade


df_1d <- 
  left_join(df_1d, unique(exportacao[,c("CO_NCM","NO_UNID", "SG_UNID")]), by = "CO_NCM")


df_1d <- 
  df_1d[,c("CO_ANO", "SUBSTANCIA", "CO_NCM", "EX_FOB.x", "QUANTIDADE", "SG_UNID", "NO_UNID", "percentual_Produto_NCM")]

# _____ descri��o NCMs
df_1d <- 
  left_join(df_1d, unique(NCM_CNAE_Relacionamentos[,c("CO_NCM","NO_NCM_POR")]))


# 1.e	Pre�o m�dio dos 3 principais produtos de exporta��o nos �ltimos 3 anos ----

df_1e <- 
  df_1d[,c("CO_ANO", "SUBSTANCIA", "CO_NCM", "NO_NCM_POR", "EX_FOB.x", "QUANTIDADE", "SG_UNID", "NO_UNID")]


df_auxiliar <- 
  summarise(group_by(.data = exportacao[, c("CO_ANO", "CO_NCM", "VALOR_(usd/un)")], CO_ANO, CO_NCM),
          "VALOR_(usd/un)" = round(median(`VALOR_(usd/un)`, na.rm = TRUE),4))


# chave prim�ria
df_auxiliar$id_NCM_ano <- 
  paste(df_auxiliar$CO_NCM, df_auxiliar$CO_ANO, sep = "_")

df_1e$id_NCM_ano <- 
  paste(df_1e$CO_NCM, df_1e$CO_ANO, sep = "_")

# uni�o com os valores unit�rios
df_1e <-
  left_join(df_1e, df_auxiliar[,c("id_NCM_ano", "VALOR_(usd/un)")], by = "id_NCM_ano")




# 2. NCMs IMPORTA��O

# _____ BASE IMPORTA�AO                           ####

#rm(exportacao)

# carregar arquivo pronto
importacao <- readRDS(file = 'D:/Users/humberto.serna/Documents/CSV_Data/ComexStat/IMP_COMPLETA.RDATA')

importacao <-
  read.table(
    file = 'D:/Users/humberto.serna/Documents/CSV_Data/ComexStat/IMP_2020.csv',
    header = TRUE,   
    sep = ";", # skip = 28737260,  23417130, nrows = 9091054,
    stringsAsFactors = FALSE, 
    colClasses = c('character','character','character','character','character','character','character','character','numeric','numeric','numeric'),
    col.names = c("CO_ANO","CO_MES","CO_NCM","CO_UNID","CO_PAIS","SG_UF_NCM","CO_VIA","CO_URF","QT_ESTAT","KG_LIQUIDO","VL_FOB"),
     quote = "\"",    #  'aspas simples na string
    encoding = "UTF-8", fill = TRUE    #   UTF-8 cont�m US-ASCII 
  )


# __________ und de medida 
importacao <- 
  left_join(importacao, und_medida, by = "CO_UNID")


# __________ importacao de produtos NCMs minera��o ----

importacao <-
  importacao[importacao$CO_NCM %in% NCM_Mineracao,]  

importacao <- 
  left_join(importacao, 
            unique(NCM_CNAE_Relacionamentos[, c("CO_NCM", "CO_FAT_AGREG", "NO_FAT_AGREG", "SUBSTANCIA")]), 
            by = "CO_NCM")


# __________ Pa�s ----
importacao <- 
  left_join(importacao, pais, by = "CO_PAIS")

# __________ Quantidades em Toneladas ----

importacao$QUANTIDADE_TON <- 
  importacao$KG_LIQUIDO / 1000

# __________ vetor de pre�os ----

importacao$`VALOR_(usd/un)` <- 
  round(
    importacao$VL_FOB /
      (importacao$QT_ESTAT), 4) 

# ____________________ tratando valores infinitos
importacao[is.infinite(importacao$`VALOR_(usd/un)`),]$`VALOR_(usd/un)` <- NaN


# __________ impondo grandezas em toneladas �s Subst�ncias do Sum�rio ----

listagem <- c("Alum�nio", "Areia", "Brita", "Calc�rio", "Carv�o", "Caulim", "Chumbo", #"�gua Mineral",
              "Cobalto", "Cobre", "Cromo", "Estanho", "Ferro", "Fosfato", "Grafita", "L�tio", "Magnesita",
              "Mangan�s", "Ni�bio", "N�quel", "Pot�ssio", "Prata", "Rochas Ornamentais", "T�ntalo", #"Ouro",
              "Terras Raras", "Tit�nio", "Tungst�nio", "Van�dio", "Zinco", "Zirc�nio")

importacao[importacao$SUBSTANCIA %in% listagem &
             importacao$SG_UNID == "KGL" & is.na(importacao$`VALOR_(usd/un)`) == FALSE,]$`VALOR_(usd/un)` <-
  importacao[importacao$SUBSTANCIA %in% listagem &
               importacao$SG_UNID == "KGL" & is.na(importacao$`VALOR_(usd/un)`) == FALSE,]$`VALOR_(usd/un)` * 1000

importacao[importacao$SUBSTANCIA %in% listagem &
             importacao$SG_UNID == "KGL" & is.na(importacao$QT_ESTAT) == FALSE,]$QT_ESTAT <-
  importacao[importacao$SUBSTANCIA %in% listagem &
               importacao$SG_UNID == "KGL" & is.na(importacao$QT_ESTAT) == FALSE,]$QT_ESTAT /1000

importacao[importacao$SUBSTANCIA %in% listagem &
             importacao$SG_UNID == "KGL", ]$SG_UNID <- "TML"

importacao[importacao$SUBSTANCIA %in% listagem &
             importacao$NO_UNID == "QUILOGRAMA LIQUIDO", ]$NO_UNID <-
  "TONELADA METRICA LIQUIDA"



# 2.a	Valor total das importa��es do ano de refer�ncia e do ano anterior ----

df_2a <-
  select(importacao, everything()) %>% #tibble()
  group_by(SUBSTANCIA, CO_ANO) %>% summarise(IMP_FOB = sum(VL_FOB), QUANTIDADE_TON = sum(QUANTIDADE_TON)) # %>% tibble()


# 2.b	Distribui��o % do total de importa��es quanto � forma: b�sico, manufaturado, etc. ----

df_2b <- 
  select(importacao, everything()) %>% #tibble()
  group_by(SUBSTANCIA, NO_FAT_AGREG, CO_ANO) %>% summarise(IMP_FOB = sum(VL_FOB), QUANTIDADE_TON = sum(QUANTIDADE_TON))

# impondo chave prim�ria p/ jun��o
df_2b$id_Subs_Ano <- 
  paste(df_2b$SUBSTANCIA, df_2b$CO_ANO, sep = "_")

df_2a$id_Subs_Ano <- 
  paste(df_2a$SUBSTANCIA, df_2a$CO_ANO, sep = "_")

df_2b <- 
  left_join(df_2b, df_2a[,c("id_Subs_Ano", "IMP_FOB")], by = "id_Subs_Ano" )

df_2b$percentual_FAT_AGREG <- 
  round((df_2b$IMP_FOB.x / df_2b$IMP_FOB.y)*100, digits = 2)


df_2b <-
  df_2b[, c("CO_ANO",
            "SUBSTANCIA",
            "NO_FAT_AGREG",
            "IMP_FOB.x",
            "QUANTIDADE_TON",
            "percentual_FAT_AGREG")]


# 2.c	Distribui��o % do total de importa��es quanto aos pa�ses de destino ----

df_2c <-
  select(importacao, everything()) %>% # tibble()
  group_by(SUBSTANCIA, CO_ANO, NO_PAIS) %>% summarise(IMP_FOB = sum(VL_FOB), QUANTIDADE_TON = sum(QUANTIDADE_TON)) # %>% tibble()


# impondo chave prim�ria p/ jun��o
df_2c$id_Subs_Ano <- 
  paste(df_2c$SUBSTANCIA, df_2c$CO_ANO, sep = "_")



df_2c <- 
  left_join(df_2c, df_2a[,c("id_Subs_Ano", "IMP_FOB")], by = "id_Subs_Ano" )

df_2c$percentual_PAIS <- 
  round((df_2c$IMP_FOB.x / df_2c$IMP_FOB.y)*100, digits = 3)


df_2c <-
  df_2c[, c("CO_ANO",
            "SUBSTANCIA",
            "NO_PAIS",
            "IMP_FOB.x",
            "QUANTIDADE_TON",
            "percentual_PAIS")]


# 2.d	Nome e NCM dos 3 principais produtos importados e seus percentuais em rela��o ao valor total de importa��es ----

df_2d <-
  select(importacao, everything()) %>% # tibble()
  group_by(SUBSTANCIA, CO_ANO, CO_NCM) %>% summarise(IMP_FOB = sum(VL_FOB), QUANTIDADE = sum(QT_ESTAT)) # %>% tibble()


# impondo chave prim�ria p/ jun��o
df_2d$id_Subs_Ano <- 
  paste(df_2d$SUBSTANCIA, df_2d$CO_ANO, sep = "_")

df_2d <- 
  left_join(df_2d, df_2a[,c("id_Subs_Ano", "IMP_FOB")], by = "id_Subs_Ano" )

df_2d$percentual_Produto_NCM <- 
  round((df_2d$IMP_FOB.x / df_2d$IMP_FOB.y)*100, digits = 3)


# extra��o 3 principais produtos importados 
lista <- list()
i <- 1
for (ano in 2020) {
  for (substancia in sort(unique(NCM_CNAE_Relacionamentos$SUBSTANCIA))) {
    lista[[i]] <-
      head(arrange(df_2d[df_2d$CO_ANO == ano &
                           df_2d$SUBSTANCIA == substancia,], desc(percentual_Produto_NCM)), 10)
    i <- i + 1
  }
}


df_2d <- 
  do.call(what = "rbind", args = lista)


# _____ coluna unidades
df_2d <- 
  left_join(df_2d, unique(importacao[,c("CO_NCM","NO_UNID", "SG_UNID")]), by = "CO_NCM")



df_2d <- 
  df_2d[,c("CO_ANO", "SUBSTANCIA", "CO_NCM", "IMP_FOB.x", "QUANTIDADE", "SG_UNID", "NO_UNID", "percentual_Produto_NCM")]

# _____ descri��o NCMs
df_2d <- 
  left_join(df_2d, unique(NCM_CNAE_Relacionamentos[,c("CO_NCM","NO_NCM_POR")]))


# 2.e	Pre�o m�dio dos 3 principais produtos de importa��o nos �ltimos 3 anos ----

df_2e <- 
  df_2d[,c("CO_ANO", "SUBSTANCIA", "CO_NCM", "NO_NCM_POR", "IMP_FOB.x", "QUANTIDADE", "SG_UNID", "NO_UNID")]


df_auxiliar <- 
  summarise(group_by(.data = importacao[, c("CO_ANO", "CO_NCM", "VALOR_(usd/un)")], CO_ANO, CO_NCM),
            "VALOR_(usd/un)" = round(median(`VALOR_(usd/un)`, na.rm = TRUE),4))


# chave prim�ria
df_auxiliar$id_NCM_ano <- 
  paste(df_auxiliar$CO_NCM, df_auxiliar$CO_ANO, sep = "_")

df_2e$id_NCM_ano <- 
  paste(df_2e$CO_NCM, df_2e$CO_ANO, sep = "_")

# uni�o com os valores unit�rios
df_2e <-
  left_join(df_2e, df_auxiliar[,c("id_NCM_ano", "VALOR_(usd/un)")], by = "id_NCM_ano")


# _____ SALDO DA BALAN�A DE BENS ----
# 3.a Saldo Total do Com�rcio Exterior de Bens do ano de refer�ncia e do ano anterior ----

df_3a <- 
  left_join(df_1a, df_2a, by = "id_Subs_Ano")[,c("SUBSTANCIA.x", "CO_ANO.x", "EX_FOB", "IMP_FOB")]


df_3a$SALDO <- 
  df_3a$EX_FOB - df_3a$IMP_FOB


colnames(df_3a) <- 
  c("SUBSTANCIA","CO_ANO","EX_FOB","IMP_FOB","SALDO")


# grava��o ----

colnames(df_1a) <- 
  c("SUBST�NCIA", "ANO", "EXP_FOB_USD", "QUANTIDADE_TON", "id_Subs_Ano")
colnames(df_1b) <- 
  c("ANO", "SUBST�NCIA", "FATOR_de_AGREGA��O", "EXP_FOB_USD", "QUANTIDADE_TON", "percentual_FAT_AGREG")
colnames(df_1c) <- 
  c("ANO", "SUBST�NCIA", "PA�S", "EXP_FOB_USD", "QUANTIDADE_TON", "percentual_PA�S")
colnames(df_1d) <- 
  c("ANO", "SUBST�NCIA", "NCM", "EX_FOB_USD", "QUANTIDADE", "SG_UNID", "NO_UNID", "percentual_Produto_NCM", "Descri��o_NCM")
colnames(df_1e) <- 
  c("ANO", "SUBST�NCIA", "NCM", "Descri��o_NCM", "EX_FOB_USD", "QUANTIDADE", "SG_UNID", "NO_UNID", "id_NCM_ano", "VALOR_(usd/un)")
colnames(df_2a) <- 
  c("SUBST�NCIA", "ANO", "IMP_FOB_USD", "QUANTIDADE_TON", "id_Subs_Ano")
colnames(df_2b) <- 
  c("ANO", "SUBST�NCIA", "FATOR_de_AGREGA��O", "EX_FOB_USD", "QUANTIDADE_TON", "percentual_FAT_AGREG")
colnames(df_2c) <- 
  c("ANO", "SUBST�NCIA", "PA�S", "IMP_FOB_USD", "QUANTIDADE_TON", "percentual_PA�S")
colnames(df_2d) <- 
  c("ANO", "SUBST�NCIA", "NCM", "IMP_FOB_USD", "QUANTIDADE", "SG_UNID", "NO_UNID", "percentual_Produto_NCM", "Descr��o_NCM")
colnames(df_2e) <- 
  c("ANO", "SUBST�NCIA", "NCM", "Descri��o_NCM", "IMP_FOB_USD", "QUANTIDADE", "SG_UNID", "NO_UNID", "id_NCM_ano", "VALOR_(usd/un)")
colnames(df_3a) <- 
  c("SUBST�NCIA", "ANO", "EXP_FOB_USD", "IMP_FOB_USD", "SALDO")


lista <- list()

lista$df <-
  list(df_1a,df_1b,df_1c,df_1d,
      df_1e,df_2a,df_2b,df_2c,
      df_2d,df_2e,df_3a)


lista$titulos <- 
  list(c(
      "Exporta��es Totais",
      "Exporta��es Totais por Fator de Agrega��o",
      "Exporta��es Totais Pa�ses",
      "Exporta��es Totais por NCM",
      "Pre�o Mediano de Exporta��o",
      "Importa��es Totais",
      "Importa��es Totais por Fator de Agrega��o",
      "Importa��es Totais Pa�ses",
      "Importa��es Totais por NCM",
      "Pre�o Mediano de Importa��o",
      "Saldo da Balan�a de Bens"))

# Lista com Dfs e nomes respectivos
substancias <- 
  sort(unique(NCM_CNAE_Relacionamentos$SUBSTANCIA))

planilhas <- list()
  
for (subs in substancias) {
  for (i in 1:length(lista$df)) {
    if (nrow(dplyr::filter(lista$df[[i]], SUBST�NCIA == subs)) == 0) {
      planilhas$df[[subs]][[i]] <- c("NADA CONSTA PARA ESSA SUBST�NCIA")
      planilhas$titulo[[subs]][[i]] <- paste(str_to_upper(subs), " - " , lista$titulos[[1]][i], sep = "")
        
    } else {
      planilhas$df[[subs]][[i]] <-
        dplyr::filter(lista$df[[i]], SUBST�NCIA == subs)
      
      planilhas$titulo[[subs]][[i]] <-
        paste(str_to_upper(subs), " - " , lista$titulos[[1]][i], sep = "")
    }
  }
}


# ciclo de salvamento 


for (subs in substancias[58]) {
  for (i in 1:11) {

# _____ estilizando as planilhas/tabelas
# create a new workbook for outputs
#++++++++++++++++++++++++++++++++++++
# possible values for type are : "xls" and "xlsx"
wb<-createWorkbook(type="xlsx")
# Define some cell styles
#++++++++++++++++++++++++++++++++++++
# Title and sub title styles
TITLE_STYLE <- CellStyle(wb)+ Font(wb,  heightInPoints=16, 
                                   isBold=TRUE, underline=0)
SUB_TITLE_STYLE <- CellStyle(wb) + 
  Font(wb,  heightInPoints=10,
       isItalic=TRUE, isBold=FALSE, color = 'dark gray')
# Styles for the data table row/column names
  # TABLE_ROWNAMES_STYLE <- CellStyle(wb) + Font(wb, isBold=TRUE)
TABLE_COLNAMES_STYLE <- CellStyle(wb) + Font(wb, isBold=TRUE) +
  Alignment(wrapText=TRUE, horizontal="ALIGN_CENTER") +
  Border(color="black", position=c("TOP", "BOTTOM"), 
         pen=c("BORDER_THIN", "BORDER_THICK")) 
# Create a new sheet in the workbook
#++++++++++++++++++++++++++++++++++++
sheet <- createSheet(wb, sheetName = "Economia_Mineral")
#++++++++++++++++++++++++
# Helper function to add titles
#++++++++++++++++++++++++
# - sheet : sheet object to contain the title
# - rowIndex : numeric value indicating the row to 
#contain the title
# - title : the text to use as title
# - titleStyle : style object to use for title
xlsx.addTitle<-function(sheet, rowIndex, title, titleStyle){
  rows <-createRow(sheet,rowIndex=rowIndex)
  sheetTitle <-createCell(rows, colIndex=1)
  setCellValue(sheetTitle[[1,1]], title)
  setCellStyle(sheetTitle[[1,1]], titleStyle)
}
# Add title and sub title into a worksheet
#++++++++++++++++++++++++++++++++++++

# Add sub title
xlsx.addTitle(sheet, rowIndex=2, 
              title="fonte: COMEX, STAT. Minist�rio da Ind�stria, Com�rcio Exterior e Servi�os. 2020.",
              titleStyle = SUB_TITLE_STYLE)

# Add title
xlsx.addTitle(sheet, rowIndex=1, title= planilhas$titulo[[subs]][i], 
              titleStyle = TITLE_STYLE)
# Add a table into a worksheet
#++++++++++++++++++++++++++++++++++++
addDataFrame(planilhas$df[[subs]][i], sheet, startRow=3, startColumn=1, 
             colnamesStyle = TABLE_COLNAMES_STYLE, row.names = FALSE)#,
             #rownamesStyle = TABLE_ROWNAMES_STYLE)
# Change column width
setColumnWidth(sheet, colIndex=c(1:ncol(data.frame(planilhas$df[[subs]][i]))), colWidth=25)

# Save the workbook to a file...
#++++++++++++++++++++++++++++++++++++
saveWorkbook(wb, file = paste("./CSV_Data/ComexStat/SUBSTANCIAS/", subs, "/", planilhas$titulo[[subs]][i],".xlsx",sep = ""))

  }
}


# for (i in 1:length(lista)) { write.table( lista[[i]], file = paste("./ComexStat/", ls(pattern = 'df_')[i], ".csv", sep = ""), sep = ";", row.names = FALSE, fileEncoding = "latin1", dec = "," )}

# Consultas ----
# as consultas mais simples n�o envolver�o grandezas, mas sim consultas Regex nas 
          # classes, sub-classes, itens e sub-itens
NCM <-
  function(ncm = '.', produto = '.') {
    ncMercosul[grepl(ncMercosul$no_ncm_por, pattern = produto) &
                 grepl(ncMercosul$co_ncm, pattern = ncm), ]
  }

CNAE <-
  function(descricao = '.') {
    CNAE_2_0[grepl(CNAE_2_0$descricao, pattern = descricao),]
  }

# Consultas que envolvam grandezas:
  # construir produto-consultas por classes de agrega��es, dentro das NCM 

  # construir produto-consultas por classes de agrega��es, dentro das CNAE
  # Ser�o v�rios GroupBy

# e isso ser� s� o come�o

#_____


# itens nas colunas

a <- list()
for (i in 1:length(colnames(NCM_CNAE_Relacionamentos))) {
  a[i] <- length(unique(NCM_CNAE_Relacionamentos[42:47, i]))
}

#colunas <- 
  data.frame(colunas = colnames(NCM_CNAE_Relacionamentos),
             itens = as.integer(a))
