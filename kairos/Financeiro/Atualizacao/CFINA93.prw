#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH" 
#include "topconn.ch" 
#INCLUDE "PROTHEUS.CH"

#DEFINE STR0001 "Faturamento Aprendiz Empregador - " + AllTrim(FWGrpName()) + " / " + AllTrim(FWFilialName())
#DEFINE STR0002 "Pesquisar"
#DEFINE STR0003 "Visualizar"
#DEFINE STR0004 "Integração Faturamento..."
#DEFINE STR0005 "Integrado"
#DEFINE STR0006 "Aguardando integração"
#DEFINE STR0007 "Relatório Integração"
#DEFINE STR0008 "Inconsistência integração"
#DEFINE STR0009 "Relatório Conferência"
#DEFINE STR0010 "Relatório Analítico"

#DEFINE TITULO_JANELA   FunName()+"-"+ProcName()
#DEFINE MENSAGEM_FATURAMENTO "Ops... Funcionalidade em desenvolvimento"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFINA93
Browse Integração de Faturamento Aprendiz Empregador
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

User Function CFINA93()
    Local oBrowse

    oBrowse	:= FWMBrowse():New()
    oBrowse:SetAlias('ZCE')
    oBrowse:SetDescription(STR0001)
    oBrowse:AddLegend("ZCE_FATURA=='1'", "BLACK"	    , STR0005)
    oBrowse:AddLegend("ZCE_FATURA=='2' .AND. EMPTY(ZCE_STDESC)"  , "YELLOW"       , STR0006)
    oBrowse:AddLegend("ZCE_FATURA=='2' .AND. !EMPTY(ZCE_STDESC)" , "RED"       , STR0008)
    oBrowse:Activate()
Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Menu Funcional

@return 	aRotina - Estrutura
			[n,1] Nome a aparecer no cabecalho
			[n,2] Nome da Rotina associada
			[n,3] Reservado
			[n,4] Tipo de Transação a ser efetuada:
				1 - Pesquisa e Posiciona em um Banco de Dados
				2 - Simplesmente Mostra os Campos
				3 - Inclui registros no Bancos de Dados
				4 - Altera o registro corrente
				5 - Remove o registro corrente do Banco de Dados
				6 - Alteração sem inclusão de registros
				7 - Cópia
			[n,5] Nivel de acesso
			[n,6] Habilita Menu Funcional
/*/
//-------------------------------------------------------------------
Static Function MenuDef()
Local aRotina 	:= {}
    ADD OPTION aRotina TITLE STR0002	ACTION 'PesqBrw'			            OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE STR0003	ACTION 'VIEWDEF.CFINA93'	            OPERATION MODEL_OPERATION_VIEW ACCESS 0
    ADD OPTION aRotina TITLE STR0004  	ACTION 'StaticCall(CFINA93,PrepInteg)'	OPERATION 8 ACCESS 0 
    ADD OPTION aRotina TITLE STR0007  	ACTION 'U_CFINR086(.F.)'	            OPERATION 8 ACCESS 0 
    ADD OPTION aRotina TITLE STR0009  	ACTION 'U_CFINR087()'	                OPERATION 8 ACCESS 0
    ADD OPTION aRotina TITLE STR0010  	ACTION 'U_CFINR93()'	                OPERATION 8 ACCESS 0
    ADD OPTION aRotina TITLE 'Legenda'  ACTION 'U_CFINA93L()'                   OPERATION 8 ACCESS 0
Return aRotina

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function ModelDef()
    Local oStruct	:= FWFormStruct(1,'ZCE',/*bAvalCampo*/,/*lViewUsado*/)
    Local oModel	:= Nil	
    oModel := MPFormModel():New('MCFINA93', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
    oModel:AddFields('DADOS', /*cOwner*/, oStruct, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
    oModel:SetPrimaryKey({"ZCE_FILIAL","ZCE_PERIOD","ZCE_CC","ZCE_MAT","ZCE_FATURA"})
    oModel:GetModel('DADOS'):SetDescription(STR0001)
Return oModel         

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function ViewDef()
    Local oView  
    Local oModel	:= FWLoadModel('CFINA93')
    Local oStruct	:= FWFormStruct(2,'ZCE')
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField('DADOS',oStruct)
    oView:CreateHorizontalBox('WINDOW',100)
    oView:SetOwnerView('DADOS','WINDOW')
Return oView

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} PrepInteg
Parametros para filtrar os registros que serão integrados
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function PrepInteg()

local cPerg  := PadR("CFINA93I", Len(SX1->X1_GRUPO)) 

If !MayIUsecode("CFINA93")
    msginfo("AVISO!!! Rotina em uso por outro usuario, aguarde liberação! ")
    Return 
Endif

ValidPerg(cPerg)

if pergunte(cPerg,.T.)
    TelaSelec()
endif 

FreeUsedCode()

Return

/*/{Protheus.doc} ValidPerg
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
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

aAdd(aRegs,{cPerg,"01","Contrato de:","","","mv_ch1" ,"C",TamSX3("ZCE_CODIGO")[1],0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","ZC0","","","",""})
aAdd(aRegs,{cPerg,"02","Local de:   ","","","mv_ch2" ,"C",TamSX3("ZCE_LOCCTR")[1],0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","ZC15","","","",""})
aAdd(aRegs,{cPerg,"03","Competência de:  ","","","mv_ch3" ,"C",TamSX3("ZCE_PERIOD")[1],0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"04","Competência até: ","","","mv_ch4" ,"C",TamSX3("ZCE_PERIOD")[1],0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} TelaSelec
Tela de confirmação dos registros que serão processados
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function TelaSelec()

local aArea 	  := GetArea()
local cAliasZCE   := GetNextAlias()
Local oButCancela
Local oButPesq
Local oButProcessa
Local oGet
Local cGet := SPACE(20)
Local oGroup1
Local oRadMenu1
Local nRadMenu1   := 1
Local oWBrowse1   := nil
Local aWBrowse1   := {}
Local oCheckBo1   := nil
Local lCheckBo1   := .F.
local _oOk 	   	  := LoadBitmap( GetResources(), "LBOK")
local _oNo 		  := LoadBitmap( GetResources(), "LBNO") 
local lProcessa   := .F.
local cQry 		  := ""

Static oDlg

cQry += " SELECT "
cQry += " ZCE_CODIGO,ZCE_LOCCTR,ZCE_PERIOD,ZCE_CNPJ,ZCE_RAZAO,R_E_C_N_O_ "
cQry += " FROM "+RetSqlName("ZCE")
cQry += " WHERE "
cQry += " D_E_L_E_T_='' "
cQry += " AND ZCE_FILIAL='"+xFilial("ZCE")+"' "
cQry += " AND ZCE_FATURA='2' "
IF !Empty(MV_PAR01)
    cQry += " AND ZCE_CODIGO='"+ALLTRIM(MV_PAR01)+"' "
endif
IF !Empty(MV_PAR02)
    cQry += " AND ZCE_LOCCTR='"+ALLTRIM(MV_PAR02)+"' "
endif
cQry += " AND ZCE_PERIOD BETWEEN '"+ALLTRIM(MV_PAR03)+"' AND '"+ALLTRIM(MV_PAR04)+"' "
cQry += " ORDER BY "
cQry += " ZCE_PERIOD,ZCE_CODIGO,ZCE_LOCCTR "

cQry := ChangeQuery(cQry)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasZCE,.T.,.T.)

While (cAliasZCE)->(!EOF()) 

    Aadd(aWBrowse1,{.T.,;
                    STRZERO(VAL((cAliasZCE)->ZCE_CODIGO),15),;
                    STRZERO(VAL((cAliasZCE)->ZCE_LOCCTR),15),;
                    ALLTRIM((cAliasZCE)->ZCE_PERIOD),;
                    ALLTRIM((cAliasZCE)->ZCE_CNPJ),;
                    ALLTRIM((cAliasZCE)->ZCE_RAZAO),;
                    (cAliasZCE)->R_E_C_N_O_})

    (cAliasZCE)->(DbSKIP())
end

(cAliasZCE)->(DbCloseArea())

if len(aWBrowse1) > 0

  DEFINE MSDIALOG oDlg TITLE "Seleção - Aprendiz Empregador" FROM 000, 000  TO 550, 800 COLORS 0, 16777215 PIXEL

    @ 002, 005 GROUP oGroup1 TO 036, 394 OF oDlg COLOR 0, 16777215 PIXEL
    @ 014, 016 MSGET oGet VAR cGet SIZE 080, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 006, 109 RADIO oRadMenu1 VAR nRadMenu1 ITEMS "Contrato","Local","CNPJ" SIZE 070, 029 OF oDlg COLOR 0, 16777215 PIXEL
    @ 014, 150 BUTTON oButPesq PROMPT "Pesquisa" SIZE 053, 013 OF oDlg ACTION (PesqList(aWBrowse1,oWBrowse1,_oOk,_oNo,nRadMenu1,cGet)) PIXEL

    @  039, 005 LISTBOX oWBrowse1 VAR cVarQ Fields HEADER " ","Contrato","Local","Periodo","CNPJ","NOME","Recno" SIZE 389, 211 ON DBLCLICK (aWBrowse1:=CA710Troca(oWBrowse1:nAt,aWBrowse1),oWBrowse1:Refresh()) ON RIGHT CLICK ListBoxAll(nRow,nCol,@oWBrowse1,_oOk,,@aWBrowse1) NOSCROLL OF oDlg PIXEL
	@  259, 006 CHECKBOX oCheckBo1 VAR lCheckBo1 PROMPT "Marca/desmarca todos" SIZE 100, 008 OF oDlg PIXEL ON CLICK (AEval(aWBrowse1, {|z| z[1] := lCheckBo1}), oWBrowse1:Refresh())
    oWBrowse1:SetArray(aWBrowse1)
	oWBrowse1:bLine := { || {If(aWBrowse1[oWBrowse1:nAt,1],_oOk,_oNo),aWBrowse1[oWBrowse1:nAt,2],aWBrowse1[oWBrowse1:nAt,3],aWBrowse1[oWBrowse1:nAt,4],aWBrowse1[oWBrowse1:nAt,5],aWBrowse1[oWBrowse1:nAt,6]}}

    @ 255, 292 BUTTON oButCancela PROMPT "Cancela" SIZE 048, 016 OF oDlg ACTION (lProcessa  := .F.,oDLg:End()) PIXEL
    @ 255, 348 BUTTON oButProcessa PROMPT "Processa" SIZE 048, 016 OF oDlg ACTION (lProcessa  := .T.,oDLg:End()) PIXEL

  ACTIVATE MSDIALOG oDlg CENTERED

  if lProcessa
  
        Processa({|| GravaZC6(aWBrowse1,1)},"Processando ressarcimento do repasse...")

        Processa({|| GravaZC6(aWBrowse1,2)},"Processando ressarcimento da CI...")

        IF MSGYESNO("Gera Relatório Integração ?", "Atencão")
		    U_CFINR086(.T.)
	    Endif
 
  endif

else

    alert("Não exitem movimentos para os parâmetros informados")
	
endif

Restarea(aArea)

return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} GravaZC6
Processa integração da tabeLa ZCE e grava ZC6
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function GravaZC6(aWBrowse1,nTpRepasse)

local aLote      := "" //GeraLote()
local cLoteini   := "" //alote[1] 
local cLotefim   := "" //alote[2] 
local cIDFatu    := ""
local dDtVencto  := Ctod("")
local nReg       := 0
local cConCob    := ""
local cConFat    := ""
local cBcoFat    := ""
local nSeqLot    := 0
local nVlrTot    := 0
local cFatura    := "" 
local cDesStatus := ""
local xContrato  := ""
local xLocal     := "" 

private aFatura  := {}

procregua(len(aWBrowse1))

aSort(aWBrowse1,,, { |x, y| x[2]+x[3] < y[2]+y[3] }) //col 2 -> contrato, col 3 -> local

Begin Transaction

    for nReg=1 to len(aWBrowse1)

        IncProc()

        cDesStatus  := ""
        cConCob     := ""
        cConFat     := ""
        cBcoFat     := ""
        cIDFatu     := ""
        dDtVencto   := ""

        if aWBrowse1[nReg][1]

            if nTpRepasse == 2 .and. !GeraCi(aWBrowse1[nReg][7]) //1-ressarcimento do repasse 2-ressarcimento da CI
                loop
            endif

            if DadosOK(aWBrowse1[nReg][7],@cDesStatus,@cConCob,@cConFat,@cBcoFat,@cIDFatu,@dDtVencto,nTpRepasse)

                if xContrato+xLocal <> aWBrowse1[nReg][2]+aWBrowse1[nReg][3]
                    aLote      := GeraLote()
                    cLoteini   := alote[1] 
                    cLotefim   := alote[2]
                    nSeqLot    := 0 
                    nVlrTot    := 0
                    xContrato  := aWBrowse1[nReg][2]
                    xLocal     := aWBrowse1[nReg][3]
                endif
                
                cFatura := "1"
                cDesStatus := "Integrado com sucesso!!!"
                nSeqLot++
                if nTpRepasse == 1 //1-ressarcimento do repasse 2-ressarcimento da CI
                    if GeraCi(aWBrowse1[nReg][7])
                        nVlrTot += ZCE->ZCE_VLTRCI
                    else
                        nVlrTot += ZCE->ZCE_VLTRCI + ZCE->ZCE_VLCI
                    endif  
                else
                    nVlrTot += ZCE->ZCE_VLCI  
                endif

                //Grava ZC6    
                RecLock("ZC6",.T.)
                    ZC6->ZC6_LOTE   := cLoteini
                    ZC6->ZC6_SEQLOT := ALLTRIM(STR(nSeqLot))
                    ZC6->ZC6_FILIAL := U_VerFilFat(cConCob,ZCE->ZCE_CODIGO,cConFat) 
                    ZC6->ZC6_IDFATU := cIDFatu
                    ZC6->ZC6_PROFAT := "8"
                    ZC6->ZC6_IDCONT := ZCE->ZCE_CODIGO
                    ZC6->ZC6_LOCREM := ZCE->ZCE_LOCCTR
                    ZC6->ZC6_CONFAT := cConFat
                    ZC6->ZC6_CONCOB := cConCob
                    ZC6->ZC6_DATVEN := dDtVencto
                    ZC6->ZC6_BCOFAT := cBcoFat
                    ZC6->ZC6_IDESTU := ZCE->ZCE_MAT
                    ZC6->ZC6_CPFEST := ZCE->ZCE_CPF
                    ZC6->ZC6_NOMEST := ZCE->ZCE_NOME
                   // ZC6->ZC6_COMPET := SUBSTR(ZCE->ZCE_PERIOD,5,2)+SUBSTR(ZCE->ZCE_PERIOD,1,4)
                    ZC6->ZC6_COMPET := ZCE->ZCE_PERIOD
                    ZC6->ZC6_TCETCA := ZCE->ZCE_MAT
                    ZC6->ZC6_LOCCON := ZCE->ZCE_LOCCTR
                    ZC6->ZC6_TIPFAT := "1"
                    if nTpRepasse == 1 //1-ressarcimento do repasse 2-ressarcimento da CI
                        if GeraCi(aWBrowse1[nReg][7])
                            ZC6->ZC6_VALOR += ZCE->ZCE_VLTRCI 
                        else
                            ZC6->ZC6_VALOR += ZCE->ZCE_VLTRCI + ZCE->ZCE_VLCI
                        endif  
                    else
                        ZC6->ZC6_VALOR  := ZCE->ZCE_VLCI  
                    endif
                    ZC6->ZC6_IDCOTR := ZCE->ZCE_CODIGO
                    ZC6->ZC6_IDLCOT := ZCE->ZCE_LOCCTR
                    ZC6->ZC6_DTINTE := Date()
                    ZC6->ZC6_HRINTE := Time()
                    ZC6->ZC6_STATUS := "1" // Pendente
                ZC6->(MsUnLock())

                //Grava ZC5
                ZC5->(DbSetOrder(08))
                if ZC5->(DbSeek(ZC6->ZC6_IDFATU))
			        RECLOCK("ZC5",.F.)
		        else
			        RECLOCK("ZC5",.T.)
		        endif
                    ZC5->ZC5_FILIAL	:= ZC6->ZC6_FILIAL
                    ZC5->ZC5_LOTE 	:= ZC6->ZC6_LOTE
                    ZC5->ZC5_IDFATU	:= ZC6->ZC6_IDFATU
                    ZC5->ZC5_IDCONT	:= ZC6->ZC6_IDCONT
                    ZC5->ZC5_CONFAT	:= ZC6->ZC6_CONFAT
                    ZC5->ZC5_CONCOB	:= ZC6->ZC6_CONCOB
                    ZC5->ZC5_LOCCON := IIF(!EMPTY(ZC6->ZC6_LOCREM),ZC6->ZC6_LOCREM,ZC6->ZC6_LOCCON)
                    ZC5->ZC5_DATVEN	:= ZC6->ZC6_DATVEN
                    ZC5->ZC5_BCOFAT	:= ZC6->ZC6_BCOFAT
                    ZC5->ZC5_DATA	:= DATE()	
                    ZC5->ZC5_COMPET	:= ZC6->ZC6_COMPET			
                    ZC5->ZC5_STATUS	:= "0"
                    ZC5->ZC5_HORINI := TIME()
                    if nTpRepasse == 1 //1-ressarcimento do repasse 2-ressarcimento da CI
                        if GeraCi(aWBrowse1[nReg][7])
                            ZC5->ZC5_TIPFAT :=  "5"
                        else
                            ZC5->ZC5_TIPFAT :=  "4"
                        endif  
                    else
                        ZC5->ZC5_TIPFAT := "1"    
                    endif
                ZC5->(MSUNLOCK())

            else
            
                 cFatura := "2"
            
            endif

            //Atualiza Status ZCE  
            ZCE->(DbGoto(aWBrowse1[nReg][7]))
            RecLock("ZCE",.F.)
                if nTpRepasse == 1 //1-ressarcimento do repasse 2-ressarcimento da CI
                    ZCE->ZCE_FATURA := cFatura
                    ZCE->ZCE_STDESC := cDesStatus
                    ZCE->ZCE_LOTE   := IIF(cFatura=="1",cLoteini,"")
                    ZCE->ZCE_SEQLOT := IIF(cFatura=="1",ALLTRIM(STR(nSeqLot)),"")
                else
                    ZCE->ZCE_FATUCI := cFatura
                    ZCE->ZCE_STDECI := cDesStatus
                    ZCE->ZCE_LOTECI := IIF(cFatura=="1",cLoteini,"")
                    ZCE->ZCE_SLOTCI := IIF(cFatura=="1",ALLTRIM(STR(nSeqLot)),"")
                endif
            ZCE->(MsUnLock())

        endif

        //Se o registro seguinte pertencer a outro contrato_local grava o lotefinal 
        //e o valor total do lote para a sequencia corrente
        if !Empty(xContrato) .and. !Empty(xLocal)
            if (nReg+1 > len(aWBrowse1)) .or. (xContrato+xLocal <> aWBrowse1[nReg+1][2]+aWBrowse1[nReg+1][3])
                AjustaCpos(cLoteini,clotefim,nSeqLot,nVlrTot,nTpRepasse)
                xContrato :=""
                xLocal :=""
            endif
        endif

    next

    //AjustaCpos(cLoteini,clotefim,nSeqLot,nVlrTot)

End Transaction

return

/*/{Protheus.doc} PesqList
//TODO Valida Clique Duplo
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function PesqList(aWBrowse1,oWBrowse1,_oOk,_oNo,nRadMenu1,cGet)

local nLin    := 0
local lAchou  := .F.
local nCol    := 0

if nRadMenu1==1 //ordena pelo contrato
    nCol := 2
elseif nRadMenu1==2 //ordena pelo local de contrato
    nCol := 3
elseif nRadMenu1==3 //ordena pelo CNPJ
    nCol := 5
else
    alert("Opção ordenação inválida!!! Selecione Contrato, Local de Contrato ou CNPJ")
    return    
endif    

aSort(aWBrowse1,,, { |x, y| x[nCol] < y[nCol] })

for nLin=1 to len(aWBrowse1)
    if alltrim(cGet) $ alltrim(aWBrowse1[nLin][nCol])
        lAchou := .T.
        exit
    endif    
next

if !lAchou 
    alert("Registro nao encontrado")
else

    oWBrowse1:SetArray(aWBrowse1)
    oWBrowse1:bLine := { || {If(aWBrowse1[oWBrowse1:nAt,1],_oOk,_oNo),aWBrowse1[oWBrowse1:nAt,2],aWBrowse1[oWBrowse1:nAt,3],aWBrowse1[oWBrowse1:nAt,4],aWBrowse1[oWBrowse1:nAt,5],aWBrowse1[oWBrowse1:nAt,6]}}

    oWBrowse1:nAt := nLin
    oWBrowse1:Refresh()

endif

return

/*/{Protheus.doc} BuscaIDFat
Gera ID Faturamento e data de Vencto
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
Static Function BuscaIDFat(cIDLocCon,cIDConCob,nTpRepasse)

local aRet      := {}
Local cUrlServ 	:= ALLTRIM(GetMv("CI_KAIROS",.F.,"https://api.hmg.ciee.org.br"))  // URL do serviço
Local cPath     := ALLTRIM(GetMv("CI_PATHIDF",.F.,"/financeiro/rh/totvs/faturamento/aprendiz-empregador/dados-calculados?"))         // Path
Local oRest 	:= Nil
Local aHeader   := {}
Local cToken	:= U_CINTK12() //Consulta Token de autenticação
Local dtProces  := substr(dtos(date()),1,4)+"-"+substr(dtos(date()),5,2)+"-"+substr(dtos(date()),7,2)
Local _cParam   := "idlocalcontrato="+alltrim(cIDLocCon)+"&idconfcobr="+alltrim(cIDConCob)+"&dtprocess="+dtProces
local cJson     := ""
local cIDFatu   := ""
local dDtVenc   := nil
local cErro     := ""
local lEncontrou := .F.

oRest := FWRest():New(cUrlServ)

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Authorization: Bearer ' + cToken )

oRest:setPath(cPath+alltrim(_cParam))

If oRest:GET(aHeader)
	cJson := oRest:GetResult()
    oJsonUN := JsonObject():new()
	oJsonUN:fromJson(AllTrim(cJson))
	dDtVenc := AllTrim(oJsonUN:GetJsonText("dataVencimento"))
    cIDFatu := AllTrim(oJsonUN:GetJsonText("idFaturaAgrupador"))
    if nTpRepasse==2 //sefor ressarcimento de CI
        cIDFatu := IIF(!EMPTY(cIDFatu),"X"+ALLTRIM(cIDFatu),cIDFatu)
    endif
    lEncontrou := .T.
else
    cJson := oRest:GetResult()
    oJsonUN := JsonObject():new()
	oJsonUN:fromJson(AllTrim(cJson))
	cErro := "IDFatura/Dt Vencto não retornado!!! - "+AllTrim(oJsonUN:GetJsonText("exceptionKey"))
endif

if !Empty(dDtVenc)
    dDtVenc := strTran(dDtVenc,"-",)
    dDtVenc := Stod(dDtVenc)
else
    dDtVenc   := ctod("")
endif

AADD(aRet,cIDFatu)
AADD(aRet,dDtVenc)
AADD(aRet,cErro)

if lEncontrou
    AADD(aFatura,{Alltrim(ZCE->ZCE_CODIGO),Alltrim(ZCE->ZCE_LOCCTR),cIDFatu,dDtVenc})
endif

RETURN(aRet)

/*/{Protheus.doc} GeraLote
Gera lote de controle
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
Static Function GeraLote()

local aRet    := {}
local cSufixo := ALLTRIM(dTos(date()) + strTran(strTran(timefull(), ":",),".",))

AADD(aRet,"FI"+cSufixo)
AADD(aRet,"FF"+cSufixo)

RETURN(aRet)

/*/{Protheus.doc} AjustaCpos()
Grava os campos ZC6_QTDE, ZC6_VALOR e ZC6_LOTE (lote final)
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
Static Function AjustaCpos(cLoteini,cLotefim,nSeqLot,nVlrTot,nTpRepasse)

local aArea      := GetArea()
local cQry       := ""
local _cAlias1   := ""
local cUpdate    := ""

if Empty(cLoteini)
    return
endif

//Atualiza os campos ZC6_QTDE e ZC6_VLRTOT
 
cUpdate := " UPDATE "+RETSQLNAME("ZC6")
cUpdate += " SET ZC6_QTDE='"+ALLTRIM(STR(nSeqLot))+"'," 
cUpdate += " ZC6_VLRTOT='"+ALLTRIM(STR(nVlrTot))+"'"
cUpdate += " WHERE D_E_L_E_T_='' "
cUpdate += " AND ZC6_LOTE = '"+cLoteini+"' "

TCSQLEXEC(cUpdate)

//Grava final do lote

_cAlias1 := GetNextAlias()

cQry += " SELECT " 
cQry += " MAX(R_E_C_N_O_) AS RECNO "
cQry += " FROM "+RetSqlName("ZC6")
cQry += " WHERE "
cQry += " D_E_L_E_T_='' AND "
cQry += " ZC6_LOTE = '"+cLoteIni+"' "

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),_cAlias1,.T.,.T.)

if (_cAlias1)->RECNO > 0
    
    //Atualiza o lote fim na ZC6
    ZC6->(DbGoto((_cAlias1)->RECNO))
    RecLock("ZC6",.F.)
         ZC6->ZC6_LOTE := cLoteFim
    ZC6->(MsUnLock())

    //Atualiza o lotefim na ZCE
    if nTpRepasse == 1 //1-ressarcimento do repasse 2-ressarcimento da CI
        cUpdate := " UPDATE "+RETSQLNAME("ZCE")
        cUpdate += " SET ZCE_LOTE='"+cLoteFim+"'
        cUpdate += " WHERE D_E_L_E_T_='' "
        cUpdate += " AND ZCE_LOTE = '"+cLoteini+"' "
        cUpdate += " AND ZCE_SEQLOT = '"+alltrim(ZC6->ZC6_SEQLOT)+"' "
    else
        cUpdate := " UPDATE "+RETSQLNAME("ZCE")
        cUpdate += " SET ZCE_LOTECI='"+cLoteFim+"'
        cUpdate += " WHERE D_E_L_E_T_='' "
        cUpdate += " AND ZCE_LOTECI = '"+cLoteini+"' "
        cUpdate += " AND ZCE_SLOTCI = '"+alltrim(ZC6->ZC6_SEQLOT)+"' "
    endif

    TCSQLEXEC(cUpdate)

endif

(_cAlias1)->(DbCloseArea())

RestArea(aArea)

return

/*/{Protheus.doc} DadosOK()
Valida dados que serão integrados
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
Static Function DadosOK(nRecno,cDesStatus,cConCob,cConFat,cBcoFat,cIDFatu,dDtVencto,nTpRepasse)

local lOK   := .T.
local aFatu := {}
local nLin  := 0
local lAchou  := .F.

//Posiciona na ZCE
ZCE->(DbGoto(nRecno))

cConCob  := GetAdvFVal("ZCI","ZCI_IDCOBR" ,XFILIAL("ZCI")+ZCE->ZCE_CODIGO+ZCE->ZCE_LOCCTR,3) 

//Busca Configuração de cobrança
if Empty(cConCob)
    lOK := .F.
    cDesStatus := "Configuração de cobrança não encontrada!!!"
endif

//Busca Configuração do faturamento
if lOK
    cConFat   := GetAdvFVal("ZC4","ZC4_IDFATU" ,XFILIAL("ZC4")+ZCE->ZCE_CODIGO,2)
    if Empty(cConFat)
        lOK := .F.
        cDesStatus := "Configuração do faturamento não encontrada!!!"          
    endif
endif

//Busca Banco do faturamento
if lOK 
    cBcoFat   := GetAdvFVal("ZC3","ZC3_BCOCON" ,XFILIAL("ZC3")+cConCob+ZCE->ZCE_CODIGO+cConFat,1)
    if Empty(cBcoFat)
        lOK := .F.
        cDesStatus := "Banco do faturamento não encontrado!!!"          
    endif
endif

//Busca do IDFat e data vencimento
if lOK

    //Busca o IDFatura e a data de vencimento dentro do array aFatura
    for nLin=1 to len(aFatura)
        if alltrim(ZCE->ZCE_CODIGO) == aFatura[nLin][1] .and. alltrim(ZCE->ZCE_LOCCTR) == aFatura[nLin][2] 
            AADD(aFatu,aFatura[nLin][3])
            AADD(aFatu,aFatura[nLin][4])
            AADD(aFatu,"")          
            lAchou := .T.
            exit
        endif    
    next

    if !lAchou
        aFatu  := BuscaIDFat(ZCE->ZCE_LOCCTR,cConCob,nTpRepasse)
    endif

    if !Empty(aFatu[3]) 
        lOK := .F.
        cDesStatus := aFatu[3]  
    else
        cIDFatu   := aFatu[1]
        dDtVencto := aFatu[2]
        if Empty(cIDFatu) .or. Empty(dDtVencto)  
            lOK := .F.
            cDesStatus := "ID Fatura ou data vencimento não informada !!! "    
        endif
    endif

endif

//Valida Matrícula   
if lOK               
    if Empty(ZCE->ZCE_MAT)
        lOK := .F.
        cDesStatus := "Matrícula do aprendiz não informada!!!"
    endif
endif

//Valida CPF
if lOK                    
    if Empty(ZCE->ZCE_CPF)
        lOK := .F.
        cDesStatus := "CPF do aprendiz não informado!!!"
    endif
endif

//Valida NOME                    
if lOK  
    if Empty(ZCE->ZCE_NOME)
        lOK := .F.
        cDesStatus := "Nome do aprendiz não informado!!!"
    endif
endif

//Valida Total Ressarcimento CI                       
if lOK  
    if ZCE->ZCE_VLTRCI <= 0
        lOK := .F.
        cDesStatus := "Total Ressarcimento CI não informado!!!"
    endif
endif

return(lOK)

/*/{Protheus.doc} CFINA93L()
Legenda
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
User Function CFINA93L()

BrwLegenda("Status da Integração","Legenda", { {"BR_PRETO" , OemToAnsi("Integrado")},;
                                               {"BR_AMARELO", OemToAnsi("Aguardando integração")},;
                                               {"BR_VERMELHO", OemToAnsi("Inconsistencia integração")}})
return

/*/{Protheus.doc} GeraCi
Retorna true caso deva ser gerado um repasse para CI separado
@author  	Marcelo Moraes
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
Static Function GeraCi(nRecno)

local lRet        := .F.
local cConCob     := ""
local cConFat     := ""

//Posiciona na ZCE
ZCE->(DbGoto(nRecno))

cConCob  := GetAdvFVal("ZCI","ZCI_IDCOBR" ,XFILIAL("ZCI")+ZCE->ZCE_CODIGO+ZCE->ZCE_LOCCTR,3) 

//Busca Configuração do faturamento
cConFat   := GetAdvFVal("ZC4","ZC4_IDFATU" ,XFILIAL("ZC4")+ZCE->ZCE_CODIGO,2)

//Busca o campo CI Separada (ZC3_CISEPA)
if GetAdvFVal("ZC3","ZC3_CISEPA" ,XFILIAL("ZC3")+cConCob+ZCE->ZCE_CODIGO+cConFat,1) == "1"
    lRet := .T.
endif

return(lRet)


