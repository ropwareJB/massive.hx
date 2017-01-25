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

class ExpressionTransformerOutward extends ExpressionTransformer{

#if macro

  public function new(context:MassContext) super(context);

  override private function onScenarioMeta(s:String){
    this.context.scenario.shift();
  }

  override private function onMassAssignment(e1:Expr, e2:Expr, meta:MetadataEntry, em:Expr){
    return em;
  }

#end

}
