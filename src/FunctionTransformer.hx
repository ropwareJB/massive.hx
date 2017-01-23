package;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import tink.await.MacroTools.*;
import tink.await.Await.*;
import tink.await.Thunk;

using tink.CoreApi;
using tink.MacroApi;
using haxe.macro.ExprTools;
using Lambda;
using tink.await.MacroTools.MacroExprTools;
#end

typedef MassContext = {}

class FunctionTransformer{
#if macro
	
	private var func:Function;
	private var expr:Expr;
	
	public function new(func:Function) {
		this.func = func;
		this.expr = func.expr;
	}
	
	public function transform():Function {
		return {
			args: func.args,
			params: func.params,
			ret: func.ret,
			expr: process(expr, {}, function(e) return e)
		};
	}	
		
	function transformObj<T:{expr:Expr}>(ol:Array<T>, ctx:MassContext, final:Array<T> -> Thunk<Expr>): Thunk<Expr> {
		var el = ol.map(function(v) return v.expr);
		return function() return transformList(el, ctx, function(transformedEl: Array<Expr>){
			return final({
				var i = 0;
				ol.map(function(v) {
					var obj = Reflect.copy(v);
					obj.expr = transformedEl[i++];
					return obj;
				});
			});
		});
	}
	
	function transformList(el:Array<Expr>, ctx:MassContext, final:Array<Expr> -> Thunk<Expr>): Thunk<Expr> {
		function transformNext(i:Int, transformedEl:Array<Expr>):Thunk<Expr> {
			if (i == el.length)
				return final(transformedEl);
			if (el[i] == null) {
				transformedEl.push(null);
				return function() return transformNext(i + 1, transformedEl);
			}
			return function() return process(el[i], ctx, function(transformed: Expr):Thunk<Expr> {
				transformedEl.push(transformed);
				return function() return transformNext(i + 1, transformedEl);
			});
		}
		
		return function() return transformNext(0, []);
	}
	
	function processControl(e: Expr, ctx:MassContext):Expr {
		if (e == null) return null;
		switch e.expr {
			case null: return null;
			case EReturn(e1): return e;
			case EThrow(e1): return e;
			case EFunction(_,_): return e;
			default: return e.map(processControl.bind(_, ctx));
		}
	}
	
	function process(e:Expr, ctx:MassContext, next:Expr -> Thunk<Expr>): Thunk<Expr> {
		if (e == null) return function() return next(null);

    trace(e);
		ctx = Reflect.copy(ctx);

		switch e.expr {
			case EBlock(el):
				if (el.length == 0) return function() return next(emptyExpr());
				function line(i:Int): Thunk<Expr> {
					if (i == el.length - 1) {
						return function() return process(el[i], ctx, next);
					}
					
					return function() return process(el[i], ctx, function(transformed: Expr) {
						var response = [transformed];
						response.push(line(i+1));
						return function() return bundle(response);
				  });
				}
				return function() return line(0);
      case EMeta(m, em):
        if(!MassiveMacro.isMassive(m.name)) return function() return process(em, ctx, function(em_2){
          return next(EMeta(m, em_2).at(e.pos));
        });
        trace("Found @:mass ~~~~~~~~`");
        trace("~~~~~~~~~~~~~~~`");
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
                var deSugar = @:pos(e.pos) macro MassiveMacro.massive($e1, $e2, $a{props});
                trace(deSugar);
                return function() return next(deSugar);
              default:
                haxe.macro.Context.error('@mass used on non-assignment', em.pos);
                return function() return process(e1, ctx, function(t1)
                  return function() return process(e2, ctx, function(t2)
                    return function() return next(EBinop(op, t1, t2).at(e.pos))
                  )
                );
            }
          //case EFunction(name,func):
          //  return function() return process(em, ctx, function(em2){
          //    return function() return next(EMeta(m,em2).at(e.pos));
          //});
          default:
            haxe.macro.Context.error('@mass used on non-assignment', em.pos);
            return function() return process(em, ctx, function(em_2){
                return function() return next(em_2);
            });
        }
			case EFor(it, expr):
        return function() return process(it, ctx, function(transformed)
          return function() return next(EFor(transformed, processControl(expr, ctx)).at(e.pos))
        );
			case EWhile(econd, e1, normalWhile):
        return function() return process(econd, ctx, function(tcond)
          return function() return next(EWhile(tcond, processControl(e1, ctx), normalWhile).at(e.pos))
        );
			case EBreak:
				return macro EBreak;
			case EContinue:
				return macro EContinue;
			case ETry(e1, catches):
        return process(e1, ctx, function(e1_2){
          function exprIdentity(e:Expr):Thunk<Expr> return e;
          var transCatches = [
            for (c in catches)
              {type: c.type, name: c.name, expr: c.expr == null ? null : (process(c.expr, ctx, exprIdentity): Expr)}
          ];
          return next(macro @:pos(e.pos) ETry(e1_2, transCatches));
        });
			case EReturn(e1):
				return function() return process(e1, ctx, function(transformed){
					return next(EReturn(transformed).at(e.pos));
        });
			case EThrow(e1):
				return function() return 
          process(e1, ctx, function(transformed)
            return macro @:pos(e.pos)
              throw $transformed
          );
			case ETernary(econd, eif, eelse) |
				 EIf (econd, eif, eelse):
					return function() return process(econd, ctx, function(tcond){
						return function() return next(EIf(tcond, processControl(eif, ctx), processControl(eelse, ctx)).at(e.pos));
          });
			case ESwitch(e1, cases, edef):
        return function() return next(processControl(e, ctx));
			case EObjectDecl(obj):
				return function() return transformObj(obj, ctx, function(transformedObjs)
					return function() return next(EObjectDecl(transformedObjs).at(e.pos))
				);
			case EVars(obj):
				return function() return transformObj(obj, ctx, function(transformedObjs)
					return function() return next(EVars(transformedObjs).at(e.pos))
				);
			case EUntyped(e1):
				return function() return process(e1, ctx, function(transformed)
					return function() return next(EUntyped(transformed).at(e.pos))
				);
			case ECast(e1, t):
				return function() return process(e1, ctx, function(transformed)
					return function() return next(ECast(transformed, t).at(e.pos))
				);
			case EBinop(op, e1, e2):
        return function() return process(e1, ctx, function(t1)
          return function() return process(e2, ctx, function(t2)
            return function() return next(EBinop(op, t1, t2).at(e.pos))
          )
        );
			case EParenthesis(e1):
				return function() return process(e1, ctx, function(t1)
					return function() return next(EParenthesis(t1).at(e.pos))
				);
			case EArray(e1, e2):
				return function() return process(e1, ctx, function(t1)
					return function() return process(e2, ctx, function(t2)
						return function() return next(EArray(t1, t2).at(e.pos))
					)
				);
			case EUnop(op, postFix, e1):
				return function() return process(e1, ctx, function(transformed)
					return function() return next(EUnop(op, postFix, transformed).at(e.pos))
				);
			case EField(e1, field):
				return function() return process(e1, ctx, function(transformed)
					return function() return next(EField(transformed, field).at(e.pos))
				);
			case ECheckType(e1, t):
				return function() return process(e1, ctx, function(transformed)
					return function() return next(ECheckType(transformed, t).at(e.pos))
				);
			case EArrayDecl(params):
				return function() return transformList(params, ctx, function(transformedParameters: Array<Expr>)
					return function() return next(EArrayDecl(transformedParameters).at(e.pos))
				);
			case ECall(e1, params):
				return function() return transformList(params, ctx, function(transformedParameters: Array<Expr>)
					return function() return process(e1, ctx, function(transformed) 
						return function() return next(ECall(transformed, transformedParameters).at(e.pos))
					)
				);
			case ENew(t, params):
				return function() return transformList(params, ctx, function(transformedParameters: Array<Expr>)
					return function() return next(ENew(t, transformedParameters).at(e.pos))
				);
			case EFunction(name, func):
        return function() return process(func.expr, ctx, function(func_expr2){
          var func2 = {args:func.args, ret:func.ret, expr:func_expr2, params:func.params};
          return function() return next(EFunction(name, func2).at(e.pos));
        });
			default:
		}
		return function() return next(e);
	}
#end
}
