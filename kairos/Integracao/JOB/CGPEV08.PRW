#INCLUDE "PROTHEUS.CH"
#INCLUDE "rwmake.ch"            
#INCLUDE "TOPCONN.CH"
/*============================================================================================================
  Funcao para buscar dados para CNAB chamada dentro dos arquivos de configuracoes dos bancos.
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
@variaveis aroteiros
//============================================================================================================*/   
User Function CGPEV08()             

Private xaTabU00B := {}
Private nPos      := 0
Private xcCod     := ""                      	// tamanho 2
Private xcIdFol   := "0"+Substr(SRA->RA_CC,2,4) // tamanho 5
Private xcMatri   := sra->ra_mat			 	// tamanho 6
Private xcIdSetor := right(sra->ra_filial,6) 	// tamanho 6
Private xCic      := CVALTOCHAR(LEFT(SRA->RA_CIC,9))// tamanho 9
Private xcLocal   := right(sra->ra_filial,4) 	// tamanho 4
Private xcDig     := CVALTOCHAR(RIGHT(SRA->RA_CIC,2))// tamanho 2
Private xWhite    := space(6)				 	// tamanho 4

// condicao qdo a rotina executada pela customizada CGPER04 
If mv_par35 == 2
	xcRoteiro := "FOL"
Else
	xcRoteiro := aroteiros[1,1]	
Endif	

fCarrTab( @xaTabU00B, "U00B", .t.) 

If Len( xaTabU00B ) == 0 
   Aviso("ATENCAO","E necessario parametrizar a tabela U00B para que os dados de 'Uso Cliente' saia no arquivo a ser importado. !",{"Sair"}) 
	  Return .F.
Else
	If (nPos := aScan(xaTabU00B,{|x| x[1] == "U00B" .And. xcRoteiro $ x[8] })) > 0
	    xcCod:= Iif(Substr(SRA->RA_FILIAL,7,2) == "02", xaTabU00B[nPos,5],xaTabU00B[nPos,6])
	    xcCod+=xcIdFol+=xcMatri+=xcIdSetor+=xCic+=xcLocal+= xcDig+=xWhite
	Else 
	   Aviso("ATENCAO","Nao foi encontrado na tabela U00B a correspondencia para o roteiro "+alltrim(MV_PAR01)+" referente ao codigo uso cliente no layout do banco",{"Sair"}) 	
	Endif
EndIf  

Return xcCod

/*============================================================================================================
	Funcao para alterar o codigo do banco qdo selecionado doc pelo bradesco.
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
//============================================================================================================*/   
User Function CGPEV08A()  
Local cxCodBanco:= "237"

If mv_par34 == 1 .And. mv_par30 == "237"

	cxCodBanco:= Substr(SRA->RA_BCDEPSA,1,3) 

Endif

Return(cxCodBanco)

/*============================================================================================================
	Funcao para retornar o tipo de transacao 
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
//============================================================================================================*/   
User Function CGPEV08B()  
Local cxTpTran:= "000" // conta corrente

If mv_par34 == 1 .And. mv_par30 == "237"
	cxTpTran:= "018" // TED
Endif

Return(cxTpTran)     

/*============================================================================================================
	Funcao para retornar o tipo de transacao 
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
//============================================================================================================*/   
User Function CGPEV08C()  
Local cxTpServ:= "30" // Pagamento de Salários

If mv_par34 == 1 .And. mv_par30 == "237"
	cxTpServ:= "20" //  Pagamento de Fornecedor
Endif

Return(cxTpServ) 


/*============================================================================================================
	Funcao para retornar o tipo de transacao 
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
//============================================================================================================*/   
User Function CGPEV08D()  
Local cxTpLanc:= "01" // Crédito em Conta Corrente

If mv_par34 == 1 .And. mv_par30 == "237"
	cxTpLanc:= "03" // DOC/TED
Endif

IF IsInCallStack("U_CFINA94")  
	IF _cTpCNAB="OP"
		cxTpLanc := "10" //ORDEM DE PAGTO
	endif
endif

Return(cxTpLanc)

/*============================================================================================================
	Funcao para retornar o CODIGO DE TED 
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
//============================================================================================================*/   
User Function CGPEV08E()  
Local cxcodTed:= SPACE(05)

If mv_par34 == 1 .And. mv_par30 == "237"
	cxcodTed:= "00010" // TED
Endif

Return(cxcodTed)


/*============================================================================================================
	Funcao para buscar a sequencia porem nao atualiza na S052.
@author     A.Shibao
@since      25/02/2019
@param
@version    P12
@return
@project
@client    Ciee
@campos  
//============================================================================================================*/   
User Function CNABSeq2()
Local cSTabela  := "S052"
Local aOldAtu   := GetArea()
Local cRet      := "000000"
Local cRCCAlias := GetNextAlias()
Local nUltSeq   := 0

Default cTipo := ''

If lUsaBanco
	
	BeginSql Alias cRCCAlias
		SELECT  R_E_C_N_O_ as RECNO, substring(RCC_CONTEU,43,6) as SEQ FROM	%table:RCC% RCC
		WHERE RCC.RCC_CODIGO   = %Exp:(cSTabela)%  AND RCC.%NotDel% and
		      substring(RCC_CONTEU,21,3) = %Exp:cCodBanco%
	EndSql

	While (cRCCAlias)->(!Eof()) 
		nUltSeq := max(nUltSeq,val((cRCCAlias)->SEQ))
		(cRCCAlias)->(dbSkip())
	EndDo
			
	nUltSeq++
	
	If nUltSeq > 999
		nUltSeq := 1
	EndIf
	cRet   := StrZero(nUltSeq,3)

(cRCCAlias)->(DBCloseArea())
EndIf

RestArea( aOldAtu )

Return( cRet )

/*/{Protheus.doc} CGPEV08F
Tratamento do numero de documento da empresa (chave do retorno)
@type  User Function
@author Carlos Henrique
@since 15/05/2020
@version version
/*/
User Function CGPEV08F()             
Local xcCod	:= AllTrim(GetNewPar("CI_CNABBA","BA"))

If mv_par35 == 2
	IF lRegFun
		xcCod+= "SRA" + SRA->RA_XID
	ELSE
		xcCod+= "SRQ" + SRQ->RQ_XID
	ENDIF
ELSE
	xcCod+= "SRD" + SRA->RA_XNUDOC //Campo com mesmo valor do RD_XNUDOC na geração do cnab
ENDIF

Return xcCod


/*/{Protheus.doc} CGPEV08V
Retorna dados bancários de acordo com a tabela ZCM
@type  User Function
@author André Brito
@since 20/08/2020
@version version
/*/
User Function CGPEV08V(nInicio)

Local cCont	    := ""
Local lCNABEX   := IsInCallStack("U_CFIN92CNABEX")  

If lCNABEX

	If nInicio == 33 
		cCont := SUBSTR(CVALTOCHAR(ZCM->ZCM_NUMCOV)+SPACE(20),1,20)  //Convenio
	ElseIf nInicio == 53
		cCont := STRZERO(VAL(SUBSTR(ZCM->ZCM_AGENC,1,LEN(ALLTRIM(ZCM->ZCM_AGENC))-1)),5) //Agencia
	ElseIf nInicio == 58
		cCont := RIGHT(ALLTRIM(ZCM->ZCM_AGENC),1) //Digito
	ElseIf nInicio == 59
		cCont := STRZERO(VAL(SUBSTR(ZCM->ZCM_CONTA,1,LEN(ALLTRIM(ZCM->ZCM_CONTA))-1)),12)//Conta Corrente
	ElseIf nInicio == 71
		cCont := RIGHT(ALLTRIM(ZCM->ZCM_CONTA),1)//Digito Conta
	EndIf
	
Else

	If nInicio == 33 
		cCont := SUBSTR(CVALTOCHAR(CCODCONVE )+SPACE(20),1,20) //Convenio
	ElseIf nInicio == 53
		cCont := STRZERO(VAL(SUBSTR(CCODAGENC,1,LEN(ALLTRIM(CCODAGENC))-1)),5) //Agencia
	ElseIf nInicio == 58
		cCont := RIGHT(ALLTRIM(CCODAGENC),1)
	ElseIf nInicio == 59
		cCont := STRZERO(VAL(SUBSTR(CCODCONTA,1,LEN(ALLTRIM(CCODCONTA))-1)),12)//Conta Corrente
	ElseIf nInicio == 71
		cCont := RIGHT(ALLTRIM(CCODCONTA),1)//Digito Conta
	EndIf
 	
EndIf

Return cCont
