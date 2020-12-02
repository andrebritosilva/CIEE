#INCLUDE "PROTHEUS.CH"

Static _cSeqRet:= ""

/*/{Protheus.doc} CFINR088
//Relatório das Ocorrencias do Retorno da Comunicacao Bancaria
Chamado pelo Ponto de Entrada F430COMP e por opção de Menu
@author Luiz Enrique de Araujo
@since 27/08/2020
@version 1.0
@param lRetBanc, _dData  Informa se chamada pelo Ponto de Entrada, Data de Referencia do Retorno
@return ${return}, ${return_description}
@type function
/*/
User Function CFINR088(lRetBanc,_dData)      

local cPerg      := PadR("CFINR88", Len(SX1->X1_GRUPO)) 

DEFAULT _dData   := dDatabase
DEFAULT lRetBanc := .F.

PRIVATE dDataRef := _dData 
PRIVATE lRetorno := lRetBanc

ValidPerg(cPerg)

oReport:= ReportDef(cPerg)  
oReport:PrintDialog()
	
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
Local aModelo:= {}

SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

AADD(aModelo, {"(Estudante)","(Beneficiario)","(Pagamento Bolsa)" })

pergunte(cPerg, !lRetorno) 

//######################
//##Cria Objeto TReport#
//######################

oReport := TReport():New("CFINR088","Relatório do Retorno da Comunicacao Bancaria - " + aModelo [1,MV_PAR06] ,cPerg,{|oReport| PrintReport(oReport)},"Relatório do Retorno da Comunicacao Bancaria")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

//MV_PAR06 == 1 .Or. lRetorno // POR MENU: MODELO ESTUDANTE ou veio pelo Retorno Bancario (P.E.)
//MV_PAR06 == 2 .Or. lRetorno // POR MENU: MODELO BENEFICIARIO ou veio pelo Retorno Bancario (P.E.)
//MV_PAR06 == 3 .Or. lRetorno // POR MENU: MODELO PAGAMENTO BOLSA ou veio pelo Retorno Bancario (P.E.)

//################
//##Cria Sessao1 #
//################
oSessao1 := TRSection():New(oReport,"OCORRENCIAS",{"TRB1"})
oSessao1 :SetReadOnly()
TRCell():New(oSessao1,"BANCO",      'TRB1',"Banco"              ,,10,.F.)
TRCell():New(oSessao1,"ID",         'TRB1',"ID Estagiario"      ,,TamSX3("RA_XID")[1]       + 5,.F.)      
TRCell():New(oSessao1,"NOME",       'TRB1',"Nome"               ,,TamSX3("RA_NOME")[1]      + 5,.F.)     
TRCell():New(oSessao1,"DATA",       'TRB1',"Baixa"              ,,17,.F.)
TRCell():New(oSessao1,"CONTRATO",   'TRB1',"Contrato"           ,,TamSX3("RA_XIDCONT")[1]   + 5,.F.)  
TRCell():New(oSessao1,"LOCALCON",   'TRB1',"Local Contr"        ,,TamSX3("RA_XIDLOCT")[1]   + 5,.F.) 
TRCell():New(oSessao1,"MATR",       'TRB3',"Matricula"          ,,TamSX3("RD_MAT")[1]       + 10,.F.) 
If MV_PAR06 == 3 .Or. lRetorno //Menu Pagamento Bolsa ou Retorno do banco    
    TRCell():New(oSessao1,"IDFOLHA",'TRB3',"ID Folha"           ,,TamSX3("RD_XIDFOL")[1]    + 5,.F.)   
    TRCell():New(oSessao1,"TITULO", 'TRB3',"Título"             ,,TamSX3("E2_NUM")[1]       + 10,.F.)  
Endif 
TRCell():New(oSessao1,"CODINCON",   'TRB1',"Ocorrencia"         ,,TamSX3("RA_XOCOREN")[1]   + 5,.F.)  
TRCell():New(oSessao1,"DESCINCON",  'TRB1',"Desc. Ocorrencia"   ,,200,.F.)
    

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

Local aArea	   	:= GetArea() 
Local cQuery   	:= "" 
Local cXSeqOcor := ""

if lRetorno // Se a chamdada da função veio do Ponto de Entrada F430COMP Retorno Bancario Cnab
    
    cXSeqOcor:= U_CSEQRET() //GetMv("MV_XSOCOR",.F.,"00000000" )
	MV_PAR01 := ""
	MV_PAR02 := "" 
	MV_PAR03 := ""
	MV_PAR04 := ""
	MV_PAR05 := ""

    IF LEFT(cXSeqOcor,1) == "A"
        MV_PAR06 := 1  //Modelo do Relatorio:  1=Estudante, 2=Beneficiario, 3= Pagamento Bolsa
    ELSEIF LEFT(cXSeqOcor,1) == "B"
        MV_PAR06 := 2  //Modelo do Relatorio:  1=Estudante, 2=Beneficiario, 3= Pagamento Bolsa
    ELSEIF LEFT(cXSeqOcor,1) == "C"
        MV_PAR06 := 3  //Modelo do Relatorio:  1=Estudante, 2=Beneficiario, 3= Pagamento Bolsa
    ENDIF
    
    MV_PAR07 := 0  //Tipo do Relatorio:    1=Inconsistencia, 2=Normal, 3= Ambos      
endif

if !lRetorno .And. (Empty(MV_PAR04) .or. Empty(MV_PAR05))
	Alert("Preencha os parâmetros para informar Periodo De/Até:")
	return
endif 

If MV_PAR06 == 1  // POR MENU: MODELO ESTUDANTE ou veio pelo Retorno Bancario (P.E.)

    cQuery := " SELECT " 
    cQuery += " RA_XID, RA_MAT, RA_NOME, RA_XIDCONT, RA_XIDLOCT, RA_BCDEPSA, RA_XOCOREN, RA_XDTEFET, RA_XDEATIV"
    cQuery += " FROM "+RetSqlName("SRA")+" SRA "
    cQuery += " WHERE " 
    cQuery += " SRA.D_E_L_E_T_='' "

    If MV_PAR07 == 1    //Somente com Inconsistencia 
        cQuery += " AND RA_XATIVO='N' And RA_XOCOREN > ' ' "
    ElseIf MV_PAR07 == 2 // Sem Inconsistencia (Normal)
        cQuery += " AND RA_XATIVO <> 'N' "
    Endif

     if lRetorno
        cQuery += " AND RA_XSOCOR ='" + cXSeqOcor + "' "
    endif

    if !Empty(MV_PAR02)
        cQuery += " AND RA_XIDCONT='"+ALLTRIM(MV_PAR02)+"' "
    endif
    if !Empty(MV_PAR03)
        cQuery += " AND RA_XIDLOCT='"+ALLTRIM(MV_PAR03)+"' "
    ENDIF

    If !Empty(MV_PAR04)
        cQuery += " AND RA_XDTEFET BETWEEN '"+DTOS(MV_PAR04)+"' AND '"+DTOS(MV_PAR05)+"' "
    Endif

    cQuery += " ORDER BY RA_BCDEPSA "

    If Select("TRB1") > 0     
        TRB1->(DbCloseArea())
    EndIf  

    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),'TRB1',.T.,.T.) 

    oReport:SetMeter(TRB1->(RecCount()))
            
    oReport:Section(1):Init()

    If TRB1->(!EOF())

        While TRB1->(!EOF())
        
            if oReport:Cancel()
                Exit
            Endif 

            oReport:IncMeter()  

            oReport:Section(1):Cell("BANCO"):SetBlock({|| SUBSTR(ALLTRIM(TRB1->RA_BCDEPSA),1,3) })  
            oReport:Section(1):Cell("ID"):SetBlock({|| ALLTRIM(TRB1->RA_XID) })  
            oReport:Section(1):Cell("NOME"):SetBlock({|| ALLTRIM(TRB1->RA_NOME) }) 
            oReport:Section(1):Cell("DATA"):SetBlock({|| STOD(TRB1->RA_XDTEFET) }) 
            oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB1->RA_XIDCONT) }) 
            oReport:Section(1):Cell("LOCALCON"):SetBlock({|| ALLTRIM(TRB1->RA_XIDLOCT) }) 
            oReport:Section(1):Cell("MATR"):SetBlock({|| ALLTRIM(TRB1->RA_MAT) })  
            oReport:Section(1):Cell("CODINCON"):SetBlock({|| ALLTRIM(TRB1->RA_XOCOREN)}) 
            oReport:Section(1):Cell("DESCINCON"):SetBlock({|| DescOcor(SUBSTR(ALLTRIM(TRB1->RA_BCDEPSA),1,3),TRB1->RA_XOCOREN,TRB1->RA_XDEATIV) })
            
            oReport:Section(1):PrintLine()
            
            TRB1->(DBSKIP())  
                
        ENDDO 
    Else
        If !lRetorno 
            MsgStop( "Sem dados para Impressão.")
        Endif
    ENDIF

    If Select("TRB1") > 0     
        TRB1->(DbCloseArea())
    EndIf  

    oReport:Section(1):Finish()

Endif

If MV_PAR06 == 2  // POR MENU: MODELO BENEFICIARIO ou veio pelo Retorno Bancario (P.E.)

    cQuery := " SELECT " 
    cQuery += " RQ_MAT, RQ_NOME,RQ_XID, RQ_XOCOREN, RQ_XDTEFET, RA_XDEATIV, RA_XIDCONT, RA_XIDLOCT, RA_BCDEPSA"
    cQuery += " FROM "+RetSqlName("SRQ")+" SRQ "
    cQuery += " INNER JOIN "+RetSqlName("SRA")+" SRA ON " 
    cQuery += " 	SRA.D_E_L_E_T_='' AND "
    cQuery += " 	RA_FILIAL=RQ_FILIAL AND "
    cQuery += "     RA_MAT=RQ_MAT"
    cQuery += " WHERE " 
    cQuery += " SRQ.D_E_L_E_T_='' "

    If MV_PAR07 == 1 
        cQuery += " AND RQ_XATIVO ='N' And RQ_XOCOREN > ' ' "
    ElseIf MV_PAR07 == 2 // Sem Inconsistencia (Normal)
        cQuery += " AND RQ_XATIVO <> 'N' "
    Endif

     if lRetorno
        cQuery += " AND RQ_XSOCOR ='" + cXSeqOcor + "' "
    endif

    if !Empty(MV_PAR02)
        cQuery += " AND RA_XIDCONT='"+ALLTRIM(MV_PAR02)+"' "
    endif
    if !Empty(MV_PAR03)
        cQuery += " AND RA_XIDLOCT='"+ALLTRIM(MV_PAR03)+"' "
    ENDIF

    If !Empty(MV_PAR04)
        cQuery += " AND RQ_XDTEFET BETWEEN '"+DTOS(MV_PAR04)+"' AND '"+DTOS(MV_PAR05)+"' "
    Endif

    cQuery += " ORDER BY RA_BCDEPSA "

    If Select("TRB2") > 0     
        TRB2->(DbCloseArea())
    EndIf  

    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),'TRB2',.T.,.T.) 

    oReport:SetMeter(TRB2->(RecCount()))
            
    oReport:Section(1):Init()

    If TRB2->(!EOF())
        While TRB2->(!EOF())
        
            if oReport:Cancel()
                Exit
            Endif 

            oReport:IncMeter()  

            oReport:Section(1):Cell("BANCO"):SetBlock({|| SUBSTR(ALLTRIM(TRB2->RA_BCDEPSA),1,3) })  
            oReport:Section(1):Cell("ID"):SetBlock({|| ALLTRIM(TRB2->RQ_XID) }) 
            oReport:Section(1):Cell("NOME"):SetBlock({|| ALLTRIM(TRB2->RQ_NOME) })  
            oReport:Section(1):Cell("DATA"):SetBlock({|| STOD(TRB2->RQ_XDTEFET) }) 
            oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB2->RA_XIDCONT) }) 
            oReport:Section(1):Cell("LOCALCON"):SetBlock({|| ALLTRIM(TRB2->RA_XIDLOCT) }) 
            oReport:Section(1):Cell("MATR"):SetBlock({|| ALLTRIM(TRB2->RQ_MAT) })  
            oReport:Section(1):Cell("CODINCON"):SetBlock({|| ALLTRIM(TRB2->RQ_XOCOREN)}) 
            oReport:Section(1):Cell("DESCINCON"):SetBlock({|| DescOcor(SUBSTR(ALLTRIM(TRB2->RA_BCDEPSA),1,3),TRB2->RQ_XOCOREN,TRB2->RA_XDEATIV) })
            
            oReport:Section(1):PrintLine()
            
            TRB2->(DBSKIP())  
                
        ENDDO
    Else
        If !lRetorno 
            MsgStop( "Sem dados para Impressão.")
        Endif
    ENDIF 

    If Select("TRB2") > 0     
        TRB2->(DbCloseArea())
    EndIf  

    oReport:Section(1):Finish()

Endif

If MV_PAR06 == 3  // POR MENU: MODELO PAGAMENTO BOLSA ou veio pelo Retorno Bancario (P.E.)

    cQuery := " SELECT " 
    cQuery += " RD_MAT, RD_XNOME, RD_XIDCNT, RD_XIDLOC, RD_XIDFOL, RD_XOCORRE, RD_DATPGT,RD_XNUMTIT, RD_XDTEFET,RA_XID, RA_BCDEPSA,RA_XDEATIV "
    cQuery += " FROM "+RetSqlName("SRD")+" SRD "
    cQuery += " INNER JOIN "+RetSqlName("SRA")+" SRA ON " 
    cQuery += " 	SRA.D_E_L_E_T_='' AND "
    cQuery += " 	RD_FILIAL=RA_FILIAL AND "
    cQuery += "     RD_MAT=RA_MAT AND "
    cQuery += "     RD_XIDCNT=RA_XIDCONT AND "
    
    if !(lRetorno)
        cQuery += "     RD_XIDLOC=RA_XIDLOCT AND "
    endif

    cQuery += " 	RD_PD='J99' " 
    cQuery += " WHERE " 
    cQuery += " SRD.D_E_L_E_T_='' "

     If MV_PAR07 == 1 
        cQuery += " AND RA_XATIVO ='N' And RD_XOCORRE > ' ' "
     ElseIf MV_PAR07 == 2 // Sem Inconsistencia (Normal)
        cQuery += " AND RA_XATIVO <> 'N' "
    Endif

     if lRetorno
        cQuery += " AND RD_XSOCOR ='" + cXSeqOcor + "' "
    endif

    if !Empty(MV_PAR01)
        cQuery += " AND RD_XIDFOL='"+ALLTRIM(MV_PAR01)+"' "
    endif
    if !Empty(MV_PAR02)
        cQuery += " AND RD_XIDCNT='"+ALLTRIM(MV_PAR02)+"' "
    endif
    if !Empty(MV_PAR03) .AND. !(lRetorno)
        cQuery += " AND RD_XIDLOC='"+ALLTRIM(MV_PAR03)+"' "
    ENDIF

    If !Empty(MV_PAR04)
        cQuery += " AND RD_XDTEFET BETWEEN '"+DTOS(MV_PAR04)+"' AND '"+DTOS(MV_PAR05)+"' "
    Endif

    cQuery += " UNION ALL "

    cQuery += " SELECT " 
    cQuery += " ZCV_MAT AS RD_MAT, ZCV_NOME AS RD_XNOME, ZCV_IDCNT AS RD_XIDCNT, ZCV_IDLOC AS RD_XIDLOC, ZCV_IDFOL AS RD_XIDFOL,"
	cQuery += " ZCV_OCORRE AS RD_XOCORRE,ZCV_DATPGT AS RD_DATPGT,ZCV_NUMTIT AS RD_XNUMTIT,ZCV_DTEFET AS RD_XDTEFET,RA_XID, RA_BCDEPSA,RA_XDEATIV "
    cQuery += " FROM "+RetSqlName("ZCV")+" ZCV "
    cQuery += " INNER JOIN "+RetSqlName("SRA")+" SRA ON " 
    cQuery += " 	SRA.D_E_L_E_T_='' AND "
    cQuery += " 	ZCV_FILIAL=RA_FILIAL AND "
    cQuery += "     ZCV_MAT=RA_MAT AND "
    cQuery += "     ZCV_IDCNT=RA_XIDCONT "

    if !(lRetorno)
        cQuery += "     AND ZCV_IDLOC=RA_XIDLOCT"
    endif

    cQuery += " WHERE " 
    cQuery += " ZCV.D_E_L_E_T_='' "

     If MV_PAR07 == 1 
        cQuery += " AND RA_XATIVO ='N' And ZCV_OCORRE > ' ' "
     ElseIf MV_PAR07 == 2 // Sem Inconsistencia (Normal)
        cQuery += " AND RA_XATIVO <> 'N' "
    Endif

     if lRetorno
        cQuery += " AND ZCV_SEQUEN ='" + cXSeqOcor + "' "
    endif

    if !Empty(MV_PAR01)
        cQuery += " AND ZCV_IDFOL='"+ALLTRIM(MV_PAR01)+"' "
    endif
    if !Empty(MV_PAR02)
        cQuery += " AND ZCV_IDCNT='"+ALLTRIM(MV_PAR02)+"' "
    endif
    if !Empty(MV_PAR03) .AND. !(lRetorno)
        cQuery += " AND ZCV_IDLOC='"+ALLTRIM(MV_PAR03)+"' "
    ENDIF

    If !Empty(MV_PAR04)
        cQuery += " AND ZCV_DTEFET BETWEEN '"+DTOS(MV_PAR04)+"' AND '"+DTOS(MV_PAR05)+"' "
    Endif

    cQuery += " ORDER BY RA_BCDEPSA "

    If Select("TRB3") > 0     
        TRB3->(DbCloseArea())
    EndIf  

    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),'TRB3',.T.,.T.) 

    oReport:SetMeter(TRB3->(RecCount()))
            
    oReport:Section(1):Init()

    If TRB3->(!EOF())

        While TRB3->(!EOF())
        
            if oReport:Cancel()
                Exit
            Endif 

            oReport:IncMeter()  

            oReport:Section(1):Cell("BANCO"):SetBlock({|| SUBSTR(ALLTRIM(TRB3->RA_BCDEPSA),1,3) })  
            oReport:Section(1):Cell("ID"):SetBlock({|| ALLTRIM(TRB3->RA_XID) })  
            oReport:Section(1):Cell("NOME"):SetBlock({|| ALLTRIM(TRB3->RD_XNOME) }) 
            oReport:Section(1):Cell("DATA"):SetBlock({|| STOD(TRB3->RD_XDTEFET) }) 
            oReport:Section(1):Cell("TITULO"):SetBlock({|| ALLTRIM(TRB3->RD_XNUMTIT) }) 
            oReport:Section(1):Cell("CONTRATO"):SetBlock({|| ALLTRIM(TRB3->RD_XIDCNT) }) 
            oReport:Section(1):Cell("LOCALCON"):SetBlock({|| ALLTRIM(TRB3->RD_XIDLOC) }) 
            oReport:Section(1):Cell("IDFOLHA"):SetBlock({|| ALLTRIM(TRB3->RD_XIDFOL) }) 
            oReport:Section(1):Cell("MATR"):SetBlock({|| ALLTRIM(TRB3->RD_MAT) })  
            oReport:Section(1):Cell("CODINCON"):SetBlock({|| ALLTRIM(TRB3->RD_XOCORRE)}) 
            oReport:Section(1):Cell("DESCINCON"):SetBlock({|| DescOcor(SUBSTR(ALLTRIM(TRB3->RA_BCDEPSA),1,3),TRB3->RD_XOCORRE,TRB3->RA_XDEATIV) })
            
            oReport:Section(1):PrintLine()
            
            TRB3->(DBSKIP())  
                
        ENDDO 
    Else
        If !lRetorno 
            MsgStop( "Sem dados para Impressão.")
        Endif
    ENDIF

    If Select("TRB3") > 0     
        TRB3->(DbCloseArea())
    EndIf  

    oReport:Section(1):Finish()

Endif

RestArea(aArea)

Return  

/*/{Protheus.doc} DescOcor
//Retorna a descrição das ocorrencias
@author Luiz Enrique
@since 27/08/2020
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function DescOcor(cBanco,cStrOcor,cDescri)

local aArea    := GetArea()
local aAreaSEB := SEB->(GetArea())
local cRet     := ""
local aOcorr   := StrTokArr(cStrOcor, "|" ) 
local nCont    := 0
local cOcorr   := ""

if len(aOcorr) > 0
    if !(cBanco $ "237,341,001,033,104")
        cBanco := "237"
    endif
	for nCont=1 to len(aOcorr)
		cBanco := AVKEY(cBanco,"EB_BANCO")
		cOcorr := AVKEY(aOcorr[nCont],"EB_REFBAN")
		SEB->(dbSetOrder(1))
		If SEB->(DBSEEK(XFILIAL("SEB")+cBanco+cOcorr+"P"))
			cRet += ALLTRIM(SEB->EB_DESCRI)+"/"
		else
			if !Empty(aOcorr[nCont])
				cRet += "Ocorrência não cadastrado/"
			endif
		endif
	next
    cRet:= Substr(cRet,1,Len(cRet)-1)
endif

//Se nao tiver codigo de ocorrencia, considera a ocorrencia cadastrada na SRA
if Empty(cRet)
	cRet := alltrim(cDescri)
endif

RestArea(aAreaSEB)
RestArea(aArea)

RETURN(cRet)

/*/{Protheus.doc} ValidPerg
//Descrição auto-gerada.
@author Luiz Enrique
@since 27/08/2020
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ValidPerg(cPerg)

Local _aArea := getarea()
//Local aPerguntas := {}
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","ID Folha:       ","","","mv_ch1" ,"C",TamSX3("ZC2_IDFOLH")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Contrato:       ","","","mv_ch2" ,"C",TamSX3("ZC0_CODIGO")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","ZC0","","","",""})
aAdd(aRegs,{cPerg,"03","Local Contrato: ","","","mv_ch3" ,"C",TamSX3("ZC1_LOCCTR")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","ZC14","","","",""})
aAdd(aRegs,{cPerg,"04","Data Baixa de:  ","","","mv_ch1" ,"D",08,0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"05","Data Baixa até: ","","","mv_ch2" ,"D",08,0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"06","Modelo:         ","Modelo","Modelo","mv_ch4","N",01,0,0,"N","","MV_PAR06","Estudante","Estudante","Estudante","","Beneficiario","Beneficiario","Beneficiario","","Pagamento Bolsa","Pagamento Bolsa","Pagamento Bolsa","","","","",""})
aAdd(aRegs,{cPerg,"07","Tipo Ocorrencia:","Tipo Ocorrencia","Tipo Ocorrencia","mv_ch5","N",01,0,0,"N","","MV_PAR07","Inconsistencia","Inconsistencia","Inconsistencia","","Normal","Normal","Normal","","Ambos","Ambos","Ambos","","","","",""})
For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

RestArea(_aArea)

Return()


User function CSEQRET(_cTipRet)

IF EMPTY(_cSeqRet)

    If _cTipRet == "A"
	    
        _cSeqRet := GetSX8Num("SRA","RA_XSOCOR")
	    ConfirmSx8()

        _cSeqRet:= "A" + RIGHT(_cSeqRet,LEN(_cSeqRet)-1) 

    ElseIf _cTipRet == "B"
	    
        _cSeqRet := GetSX8Num("SRQ","RQ_XSOCOR")
	    ConfirmSx8()

        _cSeqRet:= "B" + RIGHT(_cSeqRet,LEN(_cSeqRet)-1) 

    ElseIf _cTipRet == "C"
	    
        _cSeqRet := GetSX8Num("SRD","RD_XSOCOR")
	    ConfirmSx8()

        _cSeqRet:= "C" + RIGHT(_cSeqRet,LEN(_cSeqRet)-1)

    ENDIF    
	
ENDIF

Return _cSeqRet
   