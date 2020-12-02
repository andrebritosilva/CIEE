#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F200TIT
O ponto de entrada F200TIT do CNAB a receber, sera executado apos o Sistema ler a linha de detalhe e gravar todos os dados.
@author Danilo José Grodzicki
@since 02/03/2020
@version 1.0
@return ${return}, ${return_description}
@type user function
/*/
User Function F200TIT

Local cTab

//Atualiza campos especificos na tabela FI1
if FI1->(!EOF())
    RecLock("FI1", .F.)
    FI1->FI1_XMOTIV := SEB->EB_MOTBAN
    FI1->FI1_XDESMO := SEB->EB_DESCMOT
	FI1->(Msunlock())
ENDIF	

//Grava tabela ZCO
IF TRIM(SEB->EB_REFBAN) == "09"
	
	//Grava tabela ZCO para notificação via e-mail
	U_GravaZCO()

	//Gera fila DW3
	U_CICOBDW3(SEB->EB_REFBAN,"")

ELSEIF !(TRIM(SEB->EB_REFBAN)$"00|02|03")	

	//Gera fila DW3
	U_CICOBDW3(SEB->EB_REFBAN,"")	

ENDIF

if SEB->EB_OCORR == "02" .or. SEB->EB_OCORR == "12" .or. SEB->EB_OCORR == "14" // Entrada confirmada ou Abatimento concedido ou Vencimento alterado
	
	DbSelectArea("ZC9")  // Negociações
	ZC9->(DbSetOrder(01))
	
	cTab := GetNextAlias()
	
	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECZC9
		FROM %TABLE:ZC9% ZC9
		WHERE ZC9.ZC9_FILIAL = %xfilial:ZC9%
		  AND ZC9.ZC9_PREFIX = %Exp:SE1->E1_PREFIXO% 
		  AND ZC9.ZC9_NUMTIT = %Exp:SE1->E1_NUM% 
		  AND ZC9.ZC9_PARTIT = %Exp:SE1->E1_PARCELA% 
		  AND ZC9.ZC9_TIPTIT = %Exp:SE1->E1_TIPO% 
		  AND ZC9_TIPNEG = '4'  // Cancelamento
		  AND ZC9_STATUS = '2'  // Processado
		  AND ZC9.D_E_L_E_T_ = ''
	EndSql
	
	(cTab)->(dbSelectArea((cTab)))
	(cTab)->(dbGoTop())
	
	if (cTab)->(!Eof())
		ZC9->(dbGoto((cTab)->RECZC9))
		Reclock("ZC9",.F.)
			ZC9->ZC9_STATUS := "4"  // Exclusão do título após retorno do CNAB
		ZC9->(Msunlock())
	endif
	
	(cTab)->(dbCloseArea())
endif

IF  SE5->E5_VALOR < SE1->E1_VALOR

	MANUTSX6()
	
	_bco := "CI_CAN" + SE5->E5_BANCO 

	_InstCan := SUPERGETMV(_bco,.F.,"35")

	DBSELECTAREA("FI2")
	RECLOCK("FI2",.T.)

		FI2_FILIAL   := xFilial("FI2")
		FI2_OCORR    := _InstCan
		FI2_DESCOC   := ""    
		FI2_PREFIX   := SE1->E1_PREFIXO
		FI2_TITULO   := SE1->E1_NUM
		FI2_PARCEL   := SE1->E1_PARCELA
		FI2_TIPO     := SE1->E1_TIPO
		FI2_CODCLI   := SE1->E1_CLIENTE
		FI2_LOJCLI   := SE1->E1_LOJA
		FI2_CODFOR   := ""
		FI2_LOJFOR   := ""
		FI2_GERADO   := "2"
		FI2_NUMBOR   := SE1->E1_NUMBOR
		FI2_CARTEI   := SE1->E1_SITUACA
		FI2_DTGER    := DDATABASE
		FI2_DTOCOR   := SE5->E5_DATA 

	MSUNLOCK()


DBSELECTAREA("SE1")



 
ENDIF
 

RETURN()


STATIC Function MANUTSX6

Local cTexto		:= "Código do banco para motivo de cancelamento"
Private cConteudo	:= "CI_CAN" + SE5->E5_BANCO 
Private cDescr		:= ""
If ! SX6->( dbSeek(xFilial("SX6")+cConteudo) )
	Reclock("SX6",.T.)
	SX6->X6_FIL			:= Space(2)
	SX6->X6_VAR			:= cConteudo
	SX6->X6_DESCRIC	:= Substr(cTexto,1,Len(SX6->X6_DESCRIC))
	SX6->X6_DESC1		:= ""
	SX6->X6_DESC2		:= ""
	SX6->X6_CONTEUD	:= ""
	SX6->X6_PROPRI		:= "U" //Indica que foi criado por usuario
	SX6->( MsUnlock() )
Endif

Return Nil


//-------------------------------------------------------------------
/*/{Protheus.doc} GravaZCO

@author André Brito
@since 04/09/2020
@version P12
/*/
//-------------------------------------------------------------------

User Function GravaZCO()
Local aArea  := GetArea()
Local cEmail := ""

DbSelectArea("ZCO")
DbSetOrder(1)

cEmail := RetMail(SE1->E1_XNOME)

RecLock("ZCO",.T.) 	
ZCO->ZCO_FILIAL := SE1->E1_FILIAL
ZCO->ZCO_NUM    := SE1->E1_NUM
ZCO->ZCO_TIPO   := SE1->E1_TIPO
ZCO->ZCO_PREFIX := SE1->E1_PREFIXO
ZCO->ZCO_PARCEL := SE1->E1_PARCELA
ZCO->ZCO_CLIENT := SE1->E1_CLIENTE
ZCO->ZCO_LOJA   := SE1->E1_LOJA
ZCO->ZCO_EMISSA := SE1->E1_EMISSAO
ZCO->ZCO_VENCTO := SE1->E1_VENCTO
ZCO->ZCO_VENCRE := SE1->E1_VENCREA
ZCO->ZCO_VALOR  := SE1->E1_VALOR
ZCO->ZCO_HIST   := SE1->E1_HIST
ZCO->ZCO_XNOME  := cEmail
ZCO->(MsUnlock())
	
RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} RetMail

@author André Brito
@since 04/09/2020
@version P12
/*/
//-------------------------------------------------------------------
Static Function RetMail(cNome)

Local aArea  := GetArea()
Local cEmail := ""

DbSelectArea("ZAA")
DbSetOrder(2)

If DbSeek(xFilial("ZAA") + cNome )
	cEmail := ZAA->ZAA_EMAIL
EndIf

RestArea(aArea)
 
Return cEmail
