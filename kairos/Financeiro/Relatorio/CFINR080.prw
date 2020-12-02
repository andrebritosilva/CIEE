#INCLUDE "TOTVS.CH" 

/*/{Protheus.doc} CFINR080
Relação do Faturamento de Estagiários e Aprendizes Capacitador e Empregador
@type function
@author totvs
@since 09/06/2020
@version 1.0
@return ${return}, ${return_description}
/*/
User Function CFINR080()
LOCAL cPerg	    := "CFINR080"
LOCAL oReport   := NIL 
Local oSection	:= NIL

Pergunte(cPerg,.F.)
oReport:= TReport():New("CFINR080","Relação do Faturamento de Estagiários e Aprendizes Capacitador e Empregador",cPerg,{|oReport| C06R80RUN(oReport)},"Relação do Faturamento de Estagiários e Aprendizes Capacitador e Empregador")
oSection:= TRSection():New( oReport,"Movimento")

TRCell():New(oSection,"COL00"   ,,"Contrato"            ,, 010,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL01"   ,,"Local"               ,, 010,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL02"   ,,"CNPJ"                ,, 018,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL03"   ,,"Razão Social"        ,, 060,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL04"   ,,"Pagamento"           ,, 015,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL05"   ,,"Tipo CI"             ,, 010,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL06"   ,,"Seguimento"          ,, 012,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL07"   ,,"Produto"             ,, 012,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL08"   ,,"Atividade"           ,, 012,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL09"   ,,"Gerência"            ,, 020,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL10"   ,,"Unidade"             ,, 007,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL11"   ,,"Descrição"           ,, 020,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL12"   ,,"CR"                  ,, 007,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL13"   ,,"Descrição"           ,, 020,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL14"   ,,"Compet."             ,, 005,,,,,,,,.F.,,,)
TRCell():New(oSection,"COL15"   ,,"Valor CI Kairos"     ,"@E 9,999,999.99", 015,,,,,"RIGHT",,,.F.,,,)
TRCell():New(oSection,"COL16"   ,,"Qtd. CI"             ,, 002,,,,,"CENTER",,,.F.,,,)
TRCell():New(oSection,"COL17"   ,,"Valor CI"            ,"@E 9,999,999.99", 015,,,,,"RIGHT",,,.F.,,,)

oSection:Cell("COL03"):lLineBreak:=.t.
oSection:Cell("COL11"):lLineBreak:=.t.
oSection:Cell("COL13"):lLineBreak:=.t.

//oSection:SetLineBreak()

oReport:DisableOrientation()
oReport:SetLandScape(.T.)
oReport:PrintDialog()	
oReport:SetEdit(.F.)

RETURN
/*/{Protheus.doc} C06R80RUN
Rotina de impressão do relatório
@type function
@author totvs
@since 09/06/2020
@version 1.0
@return ${return}, ${return_description}
/*/
STATIC FUNCTION C06R80RUN(oReport)
Local oSection := oReport:Section(1)
Local cTab	   := GetNextAlias()
Local cCompDe  := Right( AllTrim(MV_PAR12), 4 ) + Left( AllTrim(MV_PAR12), 2 )
Local cCompAte := Right( AllTrim(MV_PAR13), 4 ) + Left( AllTrim(MV_PAR13), 2 )
Local cCnd     := ""
Local nTotRel  := 0
Local cCnpjBB  := ALLTRIM(SuperGetMV("CI_CNPJBB",.T.,"")) //Cnpj base da banco do brasil
Local cCnpjCX  := ALLTRIM(SuperGetMV("CI_CNPJCX",.T.,"")) //Cnpj base da caixa

IF oReport:ndevice != 4
    oSection:Cell("COL11"):Disable()
    oSection:Cell("COL13"):Disable()
endif

oBrkEmp:= TRBreak():New(oSection,{|| },{|| "Total Geral "}) 
oTotEmp:= TRFunction():New(oSection:Cell("COL15") ,,"SUM",oBrkEmp,,,,.F.,.F.,.F.,oSection)
oTotEmp:= TRFunction():New(oSection:Cell("COL16") ,,"SUM",oBrkEmp,,,,.F.,.F.,.F.,oSection)
oTotEmp:= TRFunction():New(oSection:Cell("COL17") ,,"SUM",oBrkEmp,,,,.F.,.F.,.F.,oSection)

cCnd += "AND ZC0_FORPGT IN "+FormatIn(SubStr(ALLTRIM(MV_PAR03),1,Len(ALLTRIM(MV_PAR03))-1),';')
cCnd += " AND ZC4_TIPCON IN "+FormatIn(SubStr(ALLTRIM(MV_PAR04),1,Len(ALLTRIM(MV_PAR04))-1),';')

If SUBSTR(ALLTRIM(MV_PAR05), 1, 1) != "4" .And. SUBSTR(ALLTRIM(MV_PAR05), 1, 1) != "5" 
	cCnd += " AND ZC0_TIPEMP IN "+FormatIn(SubStr(ALLTRIM(MV_PAR05),1,Len(ALLTRIM(MV_PAR05))-1),';')
EndIf

cCnd += " AND ZC0_TIPCON IN "+FormatIn(SubStr(ALLTRIM(MV_PAR06),1,Len(ALLTRIM(MV_PAR06))-1),';')
cCnd += " AND ZC0_TIPAPR IN "+FormatIn(ALLTRIM(MV_PAR07),';')

If SUBSTR(ALLTRIM(MV_PAR05), 1, 1) != "4" .And. SUBSTR(ALLTRIM(MV_PAR05), 1, 1) != "5" 
	cCnd += " AND ZC1_DOCLOC NOT LIKE '%" + cCnpjBB + "%'"
	cCnd += " AND ZC1_DOCLOC NOT LIKE '%" + cCnpjCX + "%'"
EndIf

If SUBSTR(ALLTRIM(MV_PAR05), 1, 1) == "4" 
	cCnd += " AND ZC1_DOCLOC LIKE '%" + cCnpjBB + "%'"
EndIf

If SUBSTR(ALLTRIM(MV_PAR05), 1, 1) == "5" 
	cCnd += " AND ZC1_DOCLOC LIKE '%" + cCnpjCX + "%'"
EndIf

IF MV_PAR18 == 1
    cCnd += " AND SE1.E1_TIPO = 'PR'"
ELSE    
    cCnd += " AND SE1.E1_TIPO <> 'PR'"
ENDIF

cCnd:= "%" + cCnd + "%"

BeginSql Alias cTab
    %NOPARSER%
    SELECT DISTINCT E1_XIDCNT AS COL00
           ,E1_XIDLOC AS COL01
           ,ZC1_DOCLOC AS COL02
           ,ZC1_RAZSOC AS COL03
           ,CASE ZC0_FORPGT
                WHEN '1' THEN 'Direto'
                WHEN '2' THEN 'Centralizado'
                WHEN '2' THEN 'Outras Contribuições'
                ELSE 'ND'
            END AS COL04
           ,CASE ZC4_TIPCON
                WHEN '1' THEN 'Fixo'
                WHEN '2' THEN 'Percentual'
                WHEN '3' THEN 'Não Contribui'
                ELSE 'ND'
            END AS COL05
           ,CASE ZC0_TIPEMP
                WHEN '1' THEN 'Privada'
                WHEN '2' THEN 'Publica'
                WHEN '3' THEN 'Mista'
                WHEN '4' THEN 'Banco do Brasil'
                WHEN '5' THEN 'Caixa Econômica'
                ELSE 'ND'
            END AS COL06
           ,CASE
                WHEN ZC0_TIPCON='1' THEN 'Estágio'
                WHEN ZC0_TIPCON='2' THEN 'Aprendiz'
                WHEN ZC0_TIPCON='3' THEN 'Diversos'
                ELSE 'ND'
            END AS COL07
           ,CASE
                WHEN ZC0_TIPCON='1' THEN 'Estágio'
                WHEN ZC0_TIPCON='2' AND ZC0_TIPAPR='1' THEN 'Capacitador'
                WHEN ZC0_TIPCON='2' AND ZC0_TIPAPR='2' THEN 'Empregador'
                WHEN ZC0_TIPCON='3' THEN 'Diversos'
                ELSE 'ND'
            END AS COL08
           ,CTD2.CTD_DESC01 AS COL09
           ,ZCN_CODIGO AS COL10
           ,ZCN_DLOCAL AS COL11
           ,CTD1.CTD_ITEM AS COL12
           ,CTD1.CTD_DESC01 COL13
           ,LEFT(E1_XCOMPET, 2) + '/' + RIGHT(E1_XCOMPET, 4) AS COL14
           ,ZC4_VLRCON AS COL15
           ,(E1_VLCRUZ / NULLIF(ZC4_VLRCON ,0)) COL16
           ,E1_VLCRUZ COL17
    FROM %TABLE:SE1% SE1
    INNER JOIN %TABLE:ZC0% ZC0 ON ZC0_FILIAL=%xFilial:ZC0%
        AND ZC0_CODIGO = E1_XIDCNT
        AND ZC0.D_E_L_E_T_ = ''
    INNER JOIN %TABLE:ZC1% ZC1 ON ZC1_FILIAL=%xFilial:ZC1%
        AND ZC1_CODIGO = E1_XIDCNT
        AND ZC1_LOCCTR = E1_XIDLOC
        AND ZC1.D_E_L_E_T_ = ''
    INNER JOIN %TABLE:ZC4% ZC4 ON ZC4_FILIAL=%xFilial:ZC4%
        AND ZC4_IDCONT = E1_XIDCNT
        AND ZC4_STATUS = '1'
        AND ZC4_SITCON = '1'
        AND ZC4.D_E_L_E_T_ = ''
    INNER JOIN %TABLE:ZC3%  ZC3 
        ON ZC1_CODIGO = ZC3_IDCONT 
        AND ZC3.D_E_L_E_T_ = ''   
    INNER JOIN %TABLE:ZCN% ZCN ON ZCN_FILIAL=%xFilial:ZCN%
        AND ZCN_CODIGO = ZC3_UNRESP 
        AND ZCN.D_E_L_E_T_ = ''
    INNER JOIN %TABLE:CTD% CTD1 ON CTD1.CTD_FILIAL=%xFilial:CTD%
        AND CTD1.CTD_ITEM = E1_ITEMC
        AND CTD1.D_E_L_E_T_ = ''
    INNER JOIN %TABLE:CTD% CTD2 ON CTD2.CTD_FILIAL=%xFilial:CTD%
        AND CTD2.CTD_ITEM = CTD1.CTD_XCCPDR
        AND CTD2.D_E_L_E_T_ = ''
    WHERE E1_EMIS1 BETWEEN %Exp:MV_PAR01% AND %Exp:MV_PAR02%
        AND ZCN_CODIGO BETWEEN %Exp:MV_PAR08% AND %Exp:MV_PAR09%
        AND CTD1.CTD_ITEM BETWEEN %Exp:MV_PAR10% AND %Exp:MV_PAR11% 
        AND RIGHT(E1_XCOMPET, 4) + LEFT(E1_XCOMPET, 2) BETWEEN  %Exp:cCompDe% AND %Exp:cCompAte%
        AND E1_XIDCNT BETWEEN %Exp:MV_PAR14% AND %Exp:MV_PAR15%
        AND E1_XIDLOC BETWEEN %Exp:MV_PAR16% AND %Exp:MV_PAR17%
        AND E1_XIDCNT <> ''
        AND E1_XIDLOC <> ''
        AND SE1.D_E_L_E_T_ = ''
        %Exp:cCnd%    
EndSql

COUNT TO nTotRel

oReport:SetMeter(nTotRel)

oSection:Init()

//GETLastQuery()[2]
(cTab)->(dbSelectArea((cTab)))
(cTab)->(dbGoTop())
While (cTab)->(!EOF())

    If oReport:Cancel()
        Exit
    EndIf

    oReport:IncMeter()

	oSection:Init()
    oSection:Cell("COL00"):SetBlock({|| (cTab)->COL00  })	
    oSection:Cell("COL01"):SetBlock({|| (cTab)->COL01  })
    oSection:Cell("COL02"):SetBlock({|| (cTab)->COL02  })
    oSection:Cell("COL03"):SetBlock({|| (cTab)->COL03  })
    oSection:Cell("COL04"):SetBlock({|| (cTab)->COL04  })
    oSection:Cell("COL05"):SetBlock({|| (cTab)->COL05  })
    oSection:Cell("COL06"):SetBlock({|| (cTab)->COL06  })
    oSection:Cell("COL07"):SetBlock({|| (cTab)->COL07  })
    oSection:Cell("COL08"):SetBlock({|| (cTab)->COL08  })
    oSection:Cell("COL09"):SetBlock({|| (cTab)->COL09  })
    oSection:Cell("COL10"):SetBlock({|| (cTab)->COL10  })
    oSection:Cell("COL11"):SetBlock({|| (cTab)->COL11  })
    oSection:Cell("COL12"):SetBlock({|| (cTab)->COL12  })
    oSection:Cell("COL13"):SetBlock({|| (cTab)->COL13  })
    oSection:Cell("COL14"):SetBlock({|| (cTab)->COL14  })
    oSection:Cell("COL15"):SetBlock({|| (cTab)->COL15  })
    oSection:Cell("COL16"):SetBlock({|| (cTab)->COL16  })
    oSection:Cell("COL17"):SetBlock({|| (cTab)->COL17   })
	oSection:PrintLine()

(cTab)->(DBSKIP())
END
(cTab)->(DBCLOSEAREA())

oSection:Finish()
		
RETURN
