module kali.reactive.observer;

import std.stdio;

interface Observer(A) {
	
	void onEach(A value);
	
	void onComplete();
	
	void onError(Throwable t);
}

package class Subscriber(A): Observer!A {
	private bool unsubscribed = false;
	private Observer!A observer;
	
	this(Observer!A o) {
		observer = o;
	}
	
	void onEach(A value) {
		if (!isUnsubscribe()) {
			observer.onEach(value);
		}
	}
	
	void onComplete() {
		observer.onComplete;
	}
	
	void onError(Throwable t) {
		observer.onError(t);
	}
	
	final void unsubscribe() {
		synchronized {
			unsubscribed = true;
		}
	}
	
	final bool isUnsubscribe() {
		synchronized {
			return unsubscribed;
		}
	}
}