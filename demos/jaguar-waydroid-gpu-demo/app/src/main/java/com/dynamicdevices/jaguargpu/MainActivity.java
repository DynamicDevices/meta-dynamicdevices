// SPDX-License-Identifier: GPL-3.0-only
package com.dynamicdevices.jaguargpu;

import android.app.Activity;
import android.graphics.Color;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.Locale;
import java.util.Random;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public final class MainActivity extends Activity {
    private BenchmarkRenderer renderer;
    private TextView stats;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);

        FrameLayout root = new FrameLayout(this);
        GLSurfaceView surface = new GLSurfaceView(this);
        surface.setEGLContextClientVersion(2);
        surface.setPreserveEGLContextOnPause(true);
        renderer = new BenchmarkRenderer(new StatsSink() {
            @Override
            public void update(String value) {
                showStats(value);
            }
        });
        surface.setRenderer(renderer);
        surface.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        root.addView(surface, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        stats = new TextView(this);
        stats.setTextColor(Color.WHITE);
        stats.setTextSize(20);
        stats.setPadding(24, 16, 24, 16);
        stats.setGravity(Gravity.START);
        stats.setBackgroundColor(0x99030a18);
        stats.setText("JAGUAR GPU DRIVE\nStarting GLES 2.0…");
        FrameLayout.LayoutParams overlay = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.TOP | Gravity.START);
        overlay.setMargins(24, 24, 0, 0);
        root.addView(stats, overlay);

        TextView hint = new TextView(this);
        hint.setTextColor(0xff79f7ff);
        hint.setTextSize(18);
        hint.setPadding(18, 10, 18, 10);
        hint.setBackgroundColor(0x99030a18);
        hint.setText("TAP TO CHANGE LOAD");
        FrameLayout.LayoutParams hintParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        hintParams.setMargins(0, 0, 0, 24);
        root.addView(hint, hintParams);

        View.OnClickListener cycleLoad = new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                renderer.cycleLoad();
            }
        };
        root.setOnClickListener(cycleLoad);
        surface.setOnClickListener(cycleLoad);
        hint.setOnClickListener(cycleLoad);
        setContentView(root);
    }

    private void showStats(String value) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                stats.setText(value);
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }

    private static final class BenchmarkRenderer implements GLSurfaceView.Renderer {
        private static final int[] LOADS = {2000, 10000, 40000, 80000};
        private static final String[] LOAD_NAMES = {"CRUISE", "FAST", "TURBO", "MAX"};
        private static final int MAX_PARTICLES = LOADS[LOADS.length - 1];
        private static final String VERTEX_SHADER =
                "attribute vec4 aParticle;\n"
                + "uniform float uTime;\n"
                + "varying float vGlow;\n"
                + "varying vec3 vColour;\n"
                + "void main() {\n"
                + "  float z = fract(aParticle.z - uTime * aParticle.w);\n"
                + "  float depth = 0.08 + z;\n"
                + "  float twist = uTime * 0.20 + (1.0-z) * 2.4;\n"
                + "  mat2 r = mat2(cos(twist), -sin(twist), sin(twist), cos(twist));\n"
                + "  vec2 p = r * aParticle.xy / depth;\n"
                + "  gl_Position = vec4(p * 0.72, 0.0, 1.0);\n"
                + "  gl_PointSize = 1.2 + (1.0-z) * 8.0;\n"
                + "  vGlow = (1.0-z) * smoothstep(1.3, 0.1, length(p));\n"
                + "  vColour = mix(vec3(0.10,0.45,1.0), vec3(0.15,1.0,0.82), aParticle.w*18.0);\n"
                + "}\n";
        private static final String FRAGMENT_SHADER =
                "precision mediump float;\n"
                + "varying float vGlow;\n"
                + "varying vec3 vColour;\n"
                + "void main() {\n"
                + "  vec2 q = gl_PointCoord - vec2(0.5);\n"
                + "  float d = length(q);\n"
                + "  float core = smoothstep(0.50, 0.02, d);\n"
                + "  float halo = smoothstep(0.50, 0.18, d);\n"
                + "  gl_FragColor = vec4(vColour * (core + halo*0.7) * (0.3+vGlow*1.8), core*vGlow);\n"
                + "}\n";

        private final StatsSink sink;
        private final FloatBuffer particles;
        private int program;
        private int positionHandle;
        private int timeHandle;
        private int loadIndex = 1;
        private long startNanos;
        private long sampleNanos;
        private int sampleFrames;
        private String rendererName = "detecting GPU";
        private volatile boolean loadChanged;

        BenchmarkRenderer(StatsSink sink) {
            this.sink = sink;
            float[] data = new float[MAX_PARTICLES * 4];
            Random random = new Random(0x475055);
            for (int i = 0; i < MAX_PARTICLES; i++) {
                double angle = random.nextDouble() * Math.PI * 2.0;
                double radius = Math.sqrt(random.nextDouble()) * 0.92;
                data[i * 4] = (float) (Math.cos(angle) * radius);
                data[i * 4 + 1] = (float) (Math.sin(angle) * radius);
                data[i * 4 + 2] = random.nextFloat();
                data[i * 4 + 3] = 0.010f + random.nextFloat() * 0.045f;
            }
            particles = ByteBuffer.allocateDirect(data.length * 4)
                    .order(ByteOrder.nativeOrder()).asFloatBuffer();
            particles.put(data).position(0);
        }

        @Override
        public void onSurfaceCreated(GL10 ignored, EGLConfig config) {
            program = link(VERTEX_SHADER, FRAGMENT_SHADER);
            positionHandle = GLES20.glGetAttribLocation(program, "aParticle");
            timeHandle = GLES20.glGetUniformLocation(program, "uTime");
            GLES20.glEnable(GLES20.GL_BLEND);
            GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE);
            GLES20.glClearColor(0.005f, 0.012f, 0.045f, 1.0f);
            rendererName = GLES20.glGetString(GLES20.GL_RENDERER);
            startNanos = sampleNanos = System.nanoTime();
            publish(0.0);
        }

        @Override
        public void onSurfaceChanged(GL10 ignored, int width, int height) {
            GLES20.glViewport(0, 0, width, height);
        }

        @Override
        public void onDrawFrame(GL10 ignored) {
            long now = System.nanoTime();
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
            GLES20.glUseProgram(program);
            GLES20.glUniform1f(timeHandle, (now - startNanos) / 1_000_000_000.0f);
            particles.position(0);
            GLES20.glVertexAttribPointer(positionHandle, 4, GLES20.GL_FLOAT, false, 16, particles);
            GLES20.glEnableVertexAttribArray(positionHandle);
            GLES20.glDrawArrays(GLES20.GL_POINTS, 0, LOADS[loadIndex]);

            sampleFrames++;
            if (loadChanged || now - sampleNanos >= 1_000_000_000L) {
                double fps = sampleFrames * 1_000_000_000.0 / (now - sampleNanos);
                publish(fps);
                sampleFrames = 0;
                sampleNanos = now;
                loadChanged = false;
            }
        }

        void cycleLoad() {
            loadIndex = (loadIndex + 1) % LOADS.length;
            loadChanged = true;
        }

        private void publish(double fps) {
            sink.update(String.format(Locale.US,
                    "JAGUAR GPU DRIVE  •  %s\n%.1f FPS  •  %,d particles\n%s  •  OpenGL ES 2.0",
                    LOAD_NAMES[loadIndex], fps, LOADS[loadIndex], rendererName));
        }

        private static int link(String vertexSource, String fragmentSource) {
            int vertex = compile(GLES20.GL_VERTEX_SHADER, vertexSource);
            int fragment = compile(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
            int result = GLES20.glCreateProgram();
            GLES20.glAttachShader(result, vertex);
            GLES20.glAttachShader(result, fragment);
            GLES20.glLinkProgram(result);
            int[] ok = new int[1];
            GLES20.glGetProgramiv(result, GLES20.GL_LINK_STATUS, ok, 0);
            if (ok[0] == 0) {
                throw new IllegalStateException(GLES20.glGetProgramInfoLog(result));
            }
            return result;
        }

        private static int compile(int type, String source) {
            int shader = GLES20.glCreateShader(type);
            GLES20.glShaderSource(shader, source);
            GLES20.glCompileShader(shader);
            int[] ok = new int[1];
            GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, ok, 0);
            if (ok[0] == 0) {
                throw new IllegalStateException(GLES20.glGetShaderInfoLog(shader));
            }
            return shader;
        }
    }

    private interface StatsSink {
        void update(String value);
    }
}
