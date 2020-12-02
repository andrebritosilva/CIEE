#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH" 
#include "topconn.ch" 
#INCLUDE "PROTHEUS.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} F150NOGRV
PE ENTRADA NA GERAÇÃO DO CNAB A RECEBER - utilizado para gravar a subconta no SE1
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

USER FUNCTION F150NOGRV()
RECLOCK("SE1",.F.)
SE1->E1_XSUBCTA := MV_PAR08
SE1->(MsUnlock())
Return(.T.)
