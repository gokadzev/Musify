import com.malopieds.kugou.KuGou
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Test

class Test {
    @Test
    fun test() = runBlocking {
        val lyrics = KuGou.getLyrics(title = "千年以後 (After A Thousand Years)", artist = "陳零九", duration = 285).getOrNull()
        when {
            lyrics == null -> assertTrue(false)
            else -> {
                assert(lyrics.isNotEmpty())
                println(lyrics)
                assertTrue(lyrics.contains("[00:00.00]千年以后 - 陈零九 (Nine Chen)"))
                assertTrue(lyrics.contains("[03:10.04]徘徊不定的爱 数不尽的猜"))
                assertTrue(lyrics.contains("[04:23.07]在千年以后"))
            }
        }
    }
}
