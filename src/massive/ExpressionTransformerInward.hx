package massive;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import tink.await.MacroTools.*;
import tink.await.Await.*;
import massive.MassiveMacro;

using tink.CoreApi;
using tink.MacroApi;
using haxe.macro.ExprTools;
using tink.await.MacroTools.MacroExprTools;
using Lambda;
#end

class ExpressionTransformerInward extends ExpressionTransformer{

#if macro

  public function new(context:MassContext) super(context);

  override private function onScenarioMeta(s:String){
    this.context.scenario.unshift(s);
  }

  override private function onMassAssignment(e1:Expr, e2:Expr, meta:MetadataEntry, em:Expr){
    var props = [ for(p in meta.params) {
      switch(p.expr){
        case EConst(CIdent(x)): macro '$x';
        default: 
          haxe.macro.Context.error('@mass: Expected identifier, not ${p.expr}', em.pos);
      }
    }];
    var scenario = context.scenario.length>0 ? context.scenario[0] : null;
    return @:pos(e.pos) macro massive.MassiveMacro.massAssign($e1, $e2, $a{props}, $v{scenario});
  }

#end

}
