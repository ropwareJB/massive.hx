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

class ExpressionTransformer{

#if macro
  private var context:MassContext;

  public function new(context:MassContext){
    this.context = context;
  }

  public function appliesTo(c:ClassBuilder):Bool{
    return true;
  }

  private function isMassive(s:String) return s == ':mass' || s == 'mass';
  private function isScenario(s:String) return s == ':scenario' || s == 'scenario';
  
  public function apply(e:Expr):Expr{
    switch(e.expr){
      case EMeta(m, em):
        if(isScenario(m.name)) return extScenario(e);
        if(isMassive(m.name)) return extMassive(e);
        return e;
      default:
    }
    return e;
  }

  private function extScenario(e:Expr):Expr{
    return switch e.expr{
      case EMeta(m, em):
        if(m.params == null || m.params.length != 1){
          haxe.macro.Context.error('@scenario expecting 1 argument', em.pos);
        }
        switch m.params[0].expr{
          case EConst(CString(x)): onScenarioMeta(x);
          default:
            haxe.macro.Context.error('@scenario expecting constant string', em.pos);
        }
        e;
      default:e;
    }
  }

  private function onScenarioMeta(s:String){}

  private function onMassAssignment(e1:Expr, e2:Expr, meta:MetadataEntry, em:Expr){
    return macro trace('Mass assignment failed.');
  }

  private function extMassive(e:Expr):Expr{
    return switch e.expr{
      case EMeta(m, em):
        switch(em.expr){
          case EBinop(op, e1, e2):
            switch(op){
              case OpAssign: 
                return onMassAssignment(e1, e2, m, em);
              default:
                haxe.macro.Context.error('@mass used on non-assignment', em.pos);
                e;
            }
          default:
            haxe.macro.Context.error('@mass used on non-assignment', em.pos);
            e;
        }
      default: e;
    }
  }

#end

}
