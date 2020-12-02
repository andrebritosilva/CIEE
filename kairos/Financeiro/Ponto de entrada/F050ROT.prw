#Include 'Protheus.ch'
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} F050BUT
O ponto de entrada para inclus�o de novas op��es no menu do contas a pagar
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function F050ROT()
	Local aArea	 := u_GETALLAREA()
	Local aRotAux:= aClone(ParamIxb)
	
	aadd(aRotAux,{OemToAnsi("Vis Amortiza��o"),"U_CFINE12",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Consulta aprova��o"),"U_CFINE23",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Vl.Juros/Multas"),"U_CFINE37",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Hist. Adiantamento"),"U_CFINA83",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Classificar diversos"),"U_CFINE38",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Hist. Fluig"),"U_CFINE44",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Tracker Kairos"),"U_CFINA89",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Consulta Anal�tico"),"U_CFINA98",0, len(aRotAux)+1})
	aadd(aRotAux,{OemToAnsi("Rel Confere Valida Conta"),"U_CFINE59(SE2->E2_NUM, SE2->E2_FORNECE, SE2->E2_LOJA, SE2->E2_VENCREA)",0, len(aRotAux)+1})
	
	u_GETALLAREA(aArea)
Return(aRotAux)
