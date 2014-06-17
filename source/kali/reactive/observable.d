module kali.reactive.observable;

import kali.reactive.subscribtion;
import kali.reactive.observer;

import std.functional, std.stdio, std.conv, std.container;

private class MapProxyObserver(A,B) : Observer!A {
	private B delegate(A) f;
	private Observer!B observer;
	
	this(B delegate(A) fun, Observer!B o) {
		f = fun;
		observer = o;
	}
	
	override void onEach(A value) {
		observer.onEach(f(value));
	}
	
	override void onComplete() {
		observer.onComplete;
	}

	override void onError(Throwable t) {
		observer.onError(t);
	}
}

private class FilterProxyObserver(A): Observer!A {
	private bool delegate(A) predicate;
	private Observer!A observer;
	
	this(bool delegate(A) p, Observer!A o) {
		predicate = p;
		observer = o;
	}
	
	override void onEach(A value) {
		if (predicate(value)) {
			observer.onEach(value);
		}
	}
	
	override void onComplete() {
		observer.onComplete;
	}

	override void onError(Throwable t) {
		observer.onError(t);
	}
}

private class TakeWhileProxyObserver(A): Observer!A {
		private bool delegate(A) predicate;
	private Observer!A observer;
	
	this(bool delegate(A) p, Observer!A o) {
		predicate = p;
		observer = o;
	}
	
	override void onEach(A value) {
		if (predicate(value)) {
			observer.onEach(value);
		} else {
			onComplete;
		}
	}
	
	override void onComplete() {
		observer.onComplete;
	}

	override void onError(Throwable t) {
		observer.onError(t);
	}
}

private class TakeProxyObserver(A): Observer!A {
	private immutable long limit;
	private Observer!A observer;
	private long counter = 0;
	
	this(immutable long l, Observer!A o) {
		limit = l;
		observer = o;
	}
	
	override void onEach(A value) {
		if (counter++ <= limit) {
			observer.onEach(value);
		} else {
			onComplete();
		}
	}
	
	override void onComplete() {
		observer.onComplete;
	}

	override void onError(Throwable t) {
		observer.onError(t);
	}
}

class Observable(A) {
	private void delegate(Subscriber!A) onSubscribe;
	
	public this(void delegate(Subscriber!A) o) {
		onSubscribe = o;
	}
	
	public void subscribe(Observer!A observer) {
		subscribe0(observer);
	}
	
	private void subscribe0(Observer!A observer) {
		onSubscribe(new Subscriber!A(observer));
	}
	
	private Observable!B delegate(Observable!A) fmap(B)(B delegate(A) f) {
		return (Observable!A observable) {
			Observable!B b = new Observable!B((observer) {
					MapProxyObserver!(A,B) proxyObserver = new MapProxyObserver!(A,B)(f,observer);
					observable.subscribe(proxyObserver);
			});
			return b;
		};
	}
	
	public Observable!B map(B)(B delegate(A) f) {
		return fmap!B(f)(this);
	}
	
	public Observable!A filter(bool delegate(A) p) {
		return new Observable!A((observer) {
				this.subscribe(new FilterProxyObserver!A(p, observer));
		});
	}
	
	public Observable!A take(immutable int n) {
		return new Observable!A((observer) {
				this.subscribe(new TakeProxyObserver!A(n, observer));
		});
	}
	
	public Observable!A takeWhile(bool delegate(A) p) {
		return new Observable!A((observer) {
				this.subscribe(new TakeWhileProxyObserver!A(p, observer));
		});
	}
}

C delegate(A) o(A, B, C)(C delegate(B) g, B delegate(A) f) {
	return v => g(f(v));
}

unittest {
	class SimpleObserver(T) : Observer!T {
		private int n=0;
		private int[] array = [3,4,5,6,7,8,9,10,11];
		override void onEach(T value) {
			assert(value == array[n++], "value=["~to!string(value)~"]");
		}
		
		override void onComplete() {
			writeln("Complete");
		}
		
		override void onError(Throwable t) {
			
		}
	}
	
	auto func = delegate(Subscriber!int subscriber) {
		foreach (number; 0..9) {
			subscriber.onEach(number);
		}
	};
	
	// Functor laws
	
	// fmap f . fmap g 
	Observable!int numberEmitter = new Observable!int(func);
	auto fmapF = numberEmitter.fmap((value) => value+1);
	auto fmapG = numberEmitter.fmap((value) => value+2);
	o(fmapG, fmapF)(numberEmitter).subscribe(new SimpleObserver!int);
	// fmap (f . g)
	numberEmitter.map(o((int value)=>value+2,(int value)=>value+1)).subscribe(new SimpleObserver!int);
}

unittest {
	
}