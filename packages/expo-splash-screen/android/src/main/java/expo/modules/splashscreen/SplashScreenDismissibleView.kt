package expo.modules.splashscreen

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.view.Gravity
import android.widget.Toast
import java.lang.ref.WeakReference

typealias CB = () -> Void

@SuppressLint("ViewConstructor")
class SplashScreenDismissibleView(context: Context): SplashScreenView(context) {
    fun showVisibilityWarningWithCallback(weakActivity: WeakReference<Activity>) {
        weakActivity.get()?.runOnUiThread {
            context.applicationContext?.let {
                val message = "Looks like the SplashScreen has been visible for over 20 seconds - did you forget to hide it?"

                Toast.makeText(it, message, Toast.LENGTH_LONG)
                           .apply {
                            setGravity(Gravity.CENTER or Gravity.BOTTOM, 0, 0)
                        }
                        .show()

            }
        }
    }
}