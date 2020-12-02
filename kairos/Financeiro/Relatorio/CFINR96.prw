#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} CFINR96
//Relatório analítico do repasse a receber (ICN)
@author Marcelo Moraes
@since 27/08/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function CFINR96()  

local cPerg := ""

//Verifica se existem movimentos de repasse
ZZB->(dBSetOrder(1))
If ZZB->(dBSeek(xFilial('ZZB')+AvKey(SE1->E1_NUM,"ZZB_NUMTIT")))
    oReport:=ReportDef(cPerg)  
    oReport:PrintDialog()    
else
    msginfo("Não existem movimentos de repasse para este titulo")
endif
	
RETURN

/*/{Protheus.doc} ReportDef
//Definiçãoes do relatório
@author Luiz Enrique
@since 03/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ReportDef(cPerg)

Local oReport
Local oSessao1  // Sessão para SRA 

SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

//######################
//##Cria Objeto TReport#
//######################

oReport := TReport():New("CFINR96","Relatório Analítico Repasse a Receber (ICN) ",cPerg,{|oReport| PrintReport(oReport)},"Relatório Analítico Repasse a Receber (ICN)")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

//################
//##Cria Sessao1 #
//################
oSessao1 := TRSection():New(oReport,"OCORRENCIAS",{"TRB1"})
oSessao1 :SetReadOnly()
TRCell():New(oSessao1,"repmesano",  'ZZB',"Compet"       ,,08,.F.)
TRCell():New(oSessao1,"repdatrep",  'ZZB',"Dt.Repa"   ,,08,.F.)
TRCell():New(oSessao1,"repvlrrep",  'ZZB',"Vlr.Repa"  ,"@E 999,999.99",14,.F.,,"CENTER") 
TRCell():New(oSessao1,"repdestrep", 'ZZB',"UF Des"      ,,TamSX3("A1_EST")[1],.F.) 
TRCell():New(oSessao1,"reporigrep", 'ZZB',"UF Ori"      ,,TamSX3("A1_EST")[1],.F.) 
TRCell():New(oSessao1,"repcpf",     'ZZB',"CPF"          ,,11,.F.) 
TRCell():New(oSessao1,"repcnpj",    'ZZB',"CNPJ"         ,,14,.F.) 
TRCell():New(oSessao1,"mescomp",    'ZZB',"Me.Comp"     ,,02,.F.) 
TRCell():New(oSessao1,"Anocomp",    'ZZB',"A.Comp"     ,,04,.F.) 
TRCell():New(oSessao1,"mesrep",     'ZZB',"Me.Repa"     ,,02,.F.) 
TRCell():New(oSessao1,"anorep",     'ZZB',"A.Repa"     ,,04,.F.) 
TRCell():New(oSessao1,"estnome",    'ZZB',"Nome Estag"   ,,TamSX3("RA_NOME")[1],.F.) 
TRCell():New(oSessao1,"datanasc",   'ZZB',"Dt.Nasc"      ,,08,.F.) 
TRCell():New(oSessao1,"razaosoc",   'ZZB',"Razão Soc"    ,,TamSX3("A1_NOME")[1],.F.) 
TRCell():New(oSessao1,"cnpjbase",   'ZZB',"CNPJ Base"    ,,14,.F.) 

oSessao1:SetTotalInLine(.F.)
oSessao1:SetTotalText({|| Alltrim("TOTAL")}) 

TRFunction():New(oSessao1:Cell("repvlrrep"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,"@E 999,999.99",/*uFormula*/,/*lEndSection*/,.F.,.T.)

Return oReport 

/*/{Protheus.doc} PrintReport
//Descrição auto-gerada.
@author Luiz Enrique
@since 27/08/2020
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport) 

Local aArea	   	  := GetArea() 
local cNomeEstag  := ""
local dNasc       := Ctod("")
local cRazaoSoc   := ""
local cCNPJ       := ""
local cCliente    := ""
local cLoja       := ""

oReport:SetMeter(ZZB->(RecCount()))
        
oReport:Section(1):Init()

While ZZB->(!EOF()) .and. ZZB->ZZB_NUMTIT==SE1->E1_NUM

    if oReport:Cancel()
        Exit
    Endif 

    //Busca dados do estudante
    cNomeEstag  := GetAdvFVal("SRA","RA_NOME",XFILIAL("SRA")+AvKey(ZZB->ZZB_REPCPF,"RA_CIC"),5) 
    dNasc       := GetAdvFVal("SRA","RA_NASC",XFILIAL("SRA")+AvKey(ZZB->ZZB_REPCPF,"RA_CIC"),5) 

    //Busca dados da empresa pagamento
    SX5->(dBSetOrder(1))
    If SX5->(dBSeek(xFilial('SX5')+"W1"+AvKey(ZZB->ZZB_ORIGRE,"A1_EST")))
        cCliente := SUBSTR(SX5->X5_DESCRI,1,6)
        cLoja := SUBSTR(SX5->X5_DESCRI,7,2)
    endif

    cRazaoSoc := GetAdvFVal("SA1","A1_NOME",XFILIAL("SA1")+AvKey(cCliente,"A1_COD")+AvKey(cLoja,"A1_LOJA"),1) 
    cCNPJ := GetAdvFVal("SA1","A1_CGC",XFILIAL("SA1")+AvKey(cCliente,"A1_COD")+AvKey(cLoja,"A1_LOJA"),1) 
        
    //Imprime colunas relatorio
    oReport:IncMeter()  

    oReport:Section(1):Cell("repmesano"):SetBlock({|| ZZB->ZZB_MESANO })  
    oReport:Section(1):Cell("repdatrep"):SetBlock({|| ZZB->ZZB_DATREP })  
    oReport:Section(1):Cell("repvlrrep"):SetBlock({|| ZZB->ZZB_VLRREP }) 
    oReport:Section(1):Cell("repdestrep"):SetBlock({|| ZZB->ZZB_DESTRE }) 
    oReport:Section(1):Cell("reporigrep"):SetBlock({|| ZZB->ZZB_ORIGRE }) 
    oReport:Section(1):Cell("repcpf"):SetBlock({|| ZZB->ZZB_REPCPF }) 
    oReport:Section(1):Cell("repcnpj"):SetBlock({|| ZZB->ZZB_RECNPJ }) 
    oReport:Section(1):Cell("mescomp"):SetBlock({|| STRZERO(MONTH(ZZB->ZZB_MESANO),2) }) 
    oReport:Section(1):Cell("Anocomp"):SetBlock({|| YEAR(ZZB->ZZB_MESANO) }) 
    oReport:Section(1):Cell("mesrep"):SetBlock({|| STRZERO(MONTH(ZZB->ZZB_DATREP),2) }) 
    oReport:Section(1):Cell("anorep"):SetBlock({|| YEAR(ZZB->ZZB_DATREP) }) 
    oReport:Section(1):Cell("estnome"):SetBlock({|| cNomeEstag }) 
    oReport:Section(1):Cell("datanasc"):SetBlock({|| dNasc }) 
    oReport:Section(1):Cell("razaosoc"):SetBlock({|| cRazaoSoc }) 
    oReport:Section(1):Cell("cnpjbase"):SetBlock({|| cCNPJ }) 

    oReport:Section(1):PrintLine()
    
    ZZB->(DBSKIP())  
        
ENDDO 

oReport:Section(1):Finish()

RestArea(aArea)

Return  
