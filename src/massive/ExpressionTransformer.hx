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

//typedef MassContext = {}

class ExpressionTransformer{

#if macro
  public function new(){}

  public function appliesTo(c:ClassBuilder):Bool{
    return true;
  }

  private function isMassive(s:String) return s == ':mass' || s == 'mass';
  
  public function apply(e:Expr):Expr{
    switch(e.expr){
      case EMeta(m, em):
        if(!isMassive(m.name)) return e;
        switch(em.expr){
          case EBinop(op, e1, e2):
            switch(op){
              case OpAssign: 
                var props = [ for(p in m.params) {
                  switch(p.expr){
                    case EConst(CIdent(x)): macro '$x';
                    default: 
                      haxe.macro.Context.error('@mass: Expected identifier, not ${p.expr}', em.pos);
                  }
                }];
                return @:pos(e.pos) macro massive.MassiveMacro.massAssign($e1, $e2, $a{props});
              default:
                haxe.macro.Context.error('@mass used on non-assignment', em.pos);
            }
          default:
            haxe.macro.Context.error('@mass used on non-assignment', em.pos);
        }
      default:
    }
    return e;
  }

#end

}
