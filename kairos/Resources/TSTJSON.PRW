#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"

User Function TSTJSON()

Local cJson

Local cEmp    := "01"
Local cFil    := "0001"
Local oJson   := Nil
Local cIdFatu := space(19)

RpcSetType(3)
RpcSetEnv(cEmp,cFil)

cJson := '{"sintetico": {"idfatura": 9258211678414815,"idfolha": null,"lote": "AIC9258211678414815","seqlote": 1,"processo": 4,"loterastreamento": null,"idcontrato": 157840,"idconfiguracaofaturamento": 151167,"idconfiguracaocobranca": 211678,"tipoproduto": 1,"valortotal": 150,"datavencimento": "07/12/2020","bancofaturamento": 237,"mensagemnota": "teste","analitico": [{"id": 21952444,"cpf": "78534174032","nome": "marge teste","nomeSocial": null,"competencia": "11/2020","valor": 50,"previa": 2,"repasse": {"frm": {"tipo": "N"},"empresa": {"valor": null,"percentual_pagar": null},"autonomos": {"percentual_pagar": null,"valor_pagar": null,"unidade_pagar": null,"percentual_receber": null,"valor_receber": null,"unidade_receber": null,"fato_gerador": null}},"codigo_tce_tca": 21638,"tipo_faturamento": 1,"estorno_previa": {"idfatura": null,"id": null},"idcontrato": 157840,"idlocalcontrato": 414815,"idfaturakairos": 126445}],"idlocalcontrato": 414815,"idlocalremessa": 414815,"quantidade_tce_tca": 3,"numeropedido": null}}'
//cJson := '{"sintetico": {"idfatura": 9258211678414817,"idfolha": null,"lote": "AIC9258211678414815","seqlote": 1,"processo": 4,"loterastreamento": null,"idcontrato": 157840,"idconfiguracaofaturamento": 151167,"idconfiguracaocobranca": 211678,"tipoproduto": 1,"valortotal": 150,"datavencimento": "07/12/2020","bancofaturamento": 237,"mensagemnota": "teste","analitico": [{"id": 21952444,"cpf": "78534174032","nome": "marge teste","nomeSocial": null,"competencia": "11/2020","valor": 50,"previa": 2,"repasse": {"frm": {"tipo": "N"},"empresa": {"valor": null,"percentual_pagar": null},"autonomos": {"percentual_pagar": null,"valor_pagar": null,"unidade_pagar": null,"percentual_receber": null,"valor_receber": null,"unidade_receber": null,"fato_gerador": null}},"codigo_tce_tca": 21638,"tipo_faturamento": 1,"estorno_previa": {"idfatura": null,"id": null},"idcontrato": 157840,"idlocalcontrato": 414815,"idfaturakairos": 126445}],"idlocalcontrato": 414815,"idlocalremessa": 414815,"quantidade_tce_tca": 3,"numeropedido": null}}'

oJson:= JsonObject():new()
oJson:fromJson(cJson)   
	
cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")

RpcClearEnv()

Return